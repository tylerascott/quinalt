
setwd('/homes/tscott1/win/user/quinalt')
require(foreign)
require(plyr)
require(dplyr)
require(rgdal)
require(sp)
require(rgeos)
require(maptools)
require(ggplot2)
require(reshape2)
library(RcppRoll)
library(devtools)
library(RCurl)
library(gdata)
require(proj4)
library(lubridate)

require(gridExtra)
require(lattice)
require(splancs)
require(fields)
library(raster)
library(shapefiles)
library(raster)
library(rasterVis)  # raster visualisation
library(rWBclimate)
library(mail)
library(stargazer)
library(texreg)
library(INLA)
require(xtable)
library(maptools)


#load("/homes/tscott1/win/user/quinalt/temp_workspace_precip.RData")
mod.data = read.csv('Input/temp_modeldata_precip.csv')
#load('temp_workspace_precip.RData')

#test = readOGR(dsn='government_units','state_nrcs_a_or')

INLA::inla.setOption(num.threads=16) 

#mod.data = all.params.spdf@data

mod.data$seasonal = mod.data$Abs.Month
mod.data$total.period = mod.data$Abs.Month
mod.data$sq.owqi = ((as.numeric(as.character(mod.data$owqi)))^2)
mod.data$l.owqi = log(as.numeric(as.character(mod.data$owqi)))
mod.data = filter(mod.data,YEAR>=1992)
mod.data$HUC8 = as.character(mod.data$HUC8)

covars = mod.data[,c('elevation','seaDist','HUC8','total.period','YEAR',
                     'ag.huc8','dev.huc8','wet.huc8','forst.huc8','l.owqi',
                     'owqi','monthly.precip.median',
                     'seasonal','Ag','Dev','Wetl','Forst',
                     grep('OWEB',names(mod.data),value=T))]

#k = 100000
#covars[,grep('OWEB',names(covars))] = covars[,grep('OWEB',names(covars))]/k

covars[is.na(covars)] = 0

covars$OWEB_Grant_Capacity_PriorTo12 = covars$OWEB_Grant_Capacity_All_WC - covars$OWEB_Grant_Capacity_12_WC
covars$OWEB_Grant_Capacity_PriorTo36 = covars$OWEB_Grant_Capacity_All_WC - covars$OWEB_Grant_Capacity_36_WC
covars$OWEB_Grant_Capacity_PriorTo60 = covars$OWEB_Grant_Capacity_All_WC - covars$OWEB_Grant_Capacity_60_WC

for (i in 1:ncol(covars))
{
 if (class(covars[,i]) =='numeric')
 {
   covars[,i] = as.numeric(base::scale(covars[,i],center = TRUE,scale=TRUE))
 }
}

# 
# 
# covars$elev100m = covars$elevation/100
# covars$seaDist10km = covars$seaDist/10
# covars$ag.huc8 = 100 * covars$ag.huc8
# covars$dev.huc8 = 100 * covars$dev.huc8
# covars$forst.huc8 = 100 * covars$forst.huc8
# covars$Ag = 100 * covars$Ag
# covars$Forst = 100 * covars$Forst
# covars$Dev = 100 * covars$Dev
# covars$monthly.precip.median = covars$monthly.precip.median/100




covars = mutate(covars,OWEB_Grant_All_12_WC = OWEB_Grant_Restoration_12_WC+
                  OWEB_Grant_Capacity_12_WC +
                  OWEB_Grant_Tech_12_WC +
                  OWEB_Grant_Outreach_12_WC,
                OWEB_Grant_All_36_WC = OWEB_Grant_Restoration_36_WC+
                  OWEB_Grant_Capacity_36_WC +
                  OWEB_Grant_Tech_36_WC +
                  OWEB_Grant_Outreach_36_WC,
                OWEB_Grant_All_60_WC = OWEB_Grant_Restoration_60_WC+
                  OWEB_Grant_Capacity_60_WC +
                  OWEB_Grant_Tech_60_WC +
                  OWEB_Grant_Outreach_60_WC,
                OWEB_Grant_All_12_SWCD = OWEB_Grant_Restoration_12_SWCD+
                  OWEB_Grant_Capacity_12_SWCD +
                  OWEB_Grant_Tech_12_SWCD +
                  OWEB_Grant_Outreach_12_SWCD,
                OWEB_Grant_All_36_SWCD = OWEB_Grant_Restoration_36_SWCD+
                  OWEB_Grant_Capacity_36_SWCD +
                  OWEB_Grant_Tech_36_SWCD +
                  OWEB_Grant_Outreach_36_SWCD,
                OWEB_Grant_All_60_SWCD = OWEB_Grant_Restoration_60_SWCD+
                  OWEB_Grant_Capacity_60_SWCD +
                  OWEB_Grant_Tech_60_SWCD +
                  OWEB_Grant_Outreach_60_SWCD
)

# some book keeping
n.data = length(covars$l.owqi)

#or.bond = inla.nonconvex.hull(cbind(covars$DECIMAL_LONG,covars$DECIMAL_LAT),2,2)
(mesh.a <- inla.mesh.2d(
  cbind(mod.data$Decimal_long,mod.data$Decimal_Lat),
  max.edge=c(5, 40),cut=.05))$n

spde.a <- inla.spde2.matern(mesh.a)

# Model 1: constant spatial effect
A.1 <- inla.spde.make.A(mesh.a, 
                        loc=cbind(mod.data$Decimal_long,mod.data$Decimal_Lat))
ind.1 <- inla.spde.make.index('s', mesh.a$n)
stk.1 <- inla.stack(data=list(y=covars$l.owqi), A=list(A.1,1),
                    effects=list(ind.1, list(data.frame(b0=1,covars))))


form_nonspatial <-  y ~ 0 + b0 + Ag + Forst + Dev  + 
  dev.huc8 + ag.huc8+
  forst.huc8 + elevation + seaDist + monthly.precip.median + 
  NOT_OWEB_OWRI.wq.TotalCash + 
  #f(HUC8,model='iid')+ f(total.period,model='rw2') +
  f(seasonal,model='seasonal',season.length=12)


# put all the covariates (and the intercept) in a ``design matrix'' and make the matrix for the regression problem.  Using a QR factorisation for stability (don't worry!) the regression coefficients would be t(Q)%*%(spde)
X = cbind(rep(1,n.data),
          covars$Ag, covars$Forst,
          covars$Dev, covars$dev.huc8,
          covars$ag.huc8, covars$forst.huc8,
          covars$seaDist, covars$elevation,
          covars$monthly.precip.median, covars$NOT_OWEB_OWRI.wq.TotalCash,
          covars$HUC8, covars$total.period,covars$seasonal)
n.covariates = ncol(X)
Q = qr.Q(qr(X))

form_spatial <-  y ~ 0 + b0 + Ag + Forst + Dev  + 
  dev.huc8 + ag.huc8+
  forst.huc8 + elevation + seaDist + monthly.precip.median + 
  NOT_OWEB_OWRI.wq.TotalCash + 
  f(HUC8,model='iid')+ f(total.period,model='rw2') + f(seasonal,model='seasonal',season.length=12)+ 
f(s, model=spde.a,
  extraconstr = list(A = as.matrix(t(Q)%*%A.1), e= rep(0,n.covariates)))



mod.base.nonspatial <- inla(form_nonspatial, 
                            data=data.frame(y=covars$l.owqi, covars,b0=1), 
                            control.predictor=list(compute=TRUE),
                            control.compute=list(dic=TRUE, cpo=TRUE),verbose=T,
                            control.inla = list(
                              correct = TRUE,
                              correct.factor = 10))

mod.base.spatial<- inla(form_spatial, family='gaussian',
                        data=inla.stack.data(stk.1),
                        control.predictor=list(A=inla.stack.A(stk.1), 
                          compute=TRUE),
                        #  control.inla=list(strategy='laplace'), 
                        control.compute=list(dic=TRUE, cpo=TRUE),verbose=T)

tempcoef = data.frame(exp(mod.base.nonspatial$summary.fixed[-1,c(1,3,5)]))
tempcoef.justcoef = data.frame(tempcoef[,'mean'])


tempcoef2 = data.frame(exp(mod.base.spatial$summary.fixed[-1,c(1,3,5)]))
tempcoef2.justcoef = data.frame(tempcoef2[,'mean'])



rowname.vector = c(
  "$\\%$  Agric. (100m buffer)",
  '$\\%$  Forest (100m buffer)',
  '$\\%$  Devel. (100m buffer)',
  '$\\%$  Devel. in HUC8',
  "$\\%$  Agric. in HUC8",
  '$\\%$  Forest in HUC8',
  'Elevation (10m)',
  'Dist. from coast (10km)',
  'Monthly precip.',
  'Total Non-OWEB Restoration')


library(lme4)
library(texreg)


modbase.nonspatial.present = texreg::createTexreg(
  coef.names = rownames(tempcoef),
  coef = tempcoef[,1],
  ci.low = tempcoef[,2],
  ci.up = tempcoef[,3],
  gof.names = 'DIC',
  gof = mod.base.nonspatial$dic$dic)

modbase.spatial.present = texreg::createTexreg(
  coef.names = rownames(tempcoef2),
  coef = tempcoef2[,1],
  ci.low = tempcoef2[,2],
  ci.up = tempcoef2[,3],
  gof.names = 'DIC',
  gof = mod.base.spatial$dic$dic)


texreg(l = list(modbase.nonspatial.present,modbase.spatial.present),
       stars=numeric(0),ci.test = 1,digits = 3,
       caption = "Baseline model w/ and w/out spatial correlation", caption.above = TRUE, 
       custom.model.names = c('w/out spatial correlation','w/ spatial correlation'),
       label = c('table:basemods'),
       custom.note = "$^* 1$ outside the credible interval",
       custom.coef.names = rowname.vector,
       file='/homes/tscott1/win/user/quinalt/JPART_Submission/Version2/basemods.tex')

# put all the covariates (and the intercept) in a ``design matrix'' and make the matrix for the regression problem.  Using a QR factorisation for stability (don't worry!) the regression coefficients would be t(Q)%*%(spde)
X = cbind(rep(1,n.data),
          covars$Ag, covars$Forst,
          covars$Dev, covars$dev.huc8,
          covars$ag.huc8, covars$forst.huc8,
          covars$seaDist, covars$elevation,
          covars$monthly.precip.median, covars$NOT_OWEB_OWRI.wq.TotalCash,
          covars$OWEB_Grant_All_12_WC,
            covars$OWEB_Grant_All_12_SWCD,
            covars$OWEB_Grant_All_12_WC*covars$OWEB_Grant_All_12_SWCD,
          covars$HUC8, covars$total.period,covars$seasonal)
n.covariates = ncol(X)
Q = qr.Q(qr(X))



form_all_12m <-  y ~ 0 + b0 + Ag + Forst + Dev  + 
  dev.huc8 + ag.huc8+
  forst.huc8 + elevation + seaDist + 
  monthly.precip.median + 
  NOT_OWEB_OWRI.wq.TotalCash + 
  OWEB_Grant_All_12_WC + 
  OWEB_Grant_All_12_SWCD + 
  OWEB_Grant_All_12_WC:OWEB_Grant_All_12_SWCD +
  f(HUC8,model='iid')+ f(total.period,model='rw2') + f(seasonal,model='seasonal',season.length=12)+ 
  f(s, model=spde.a,
    extraconstr = list(A = as.matrix(t(Q)%*%A.1), e= rep(0,n.covariates)))


mod.all.12m <- inla(form_all_12m, family='gaussian', data=inla.stack.data(stk.1),
                    control.predictor=list(A=inla.stack.A(stk.1), compute=TRUE),
                    #  control.inla=list(strategy='laplace'), 
                    control.compute=list(dic=TRUE, cpo=TRUE),verbose=T)

# put all the covariates (and the intercept) in a ``design matrix'' and make the matrix for the regression problem.  Using a QR factorisation for stability (don't worry!) the regression coefficients would be t(Q)%*%(spde)
X = cbind(rep(1,n.data),
          covars$Ag, covars$Forst,
          covars$Dev, covars$dev.huc8,
          covars$ag.huc8, covars$forst.huc8,
          covars$seaDist, covars$elevation,
          covars$monthly.precip.median, covars$NOT_OWEB_OWRI.wq.TotalCash,
          covars$OWEB_Grant_All_36_WC,
          covars$OWEB_Grant_All_36_SWCD,
          covars$OWEB_Grant_All_36_WC*covars$OWEB_Grant_All_36_SWCD,
          covars$HUC8, covars$total.period,covars$seasonal)
n.covariates = ncol(X)
Q = qr.Q(qr(X))


form_all_36m <-  y ~ 0 + b0 + Ag + Forst + Dev  + 
  dev.huc8 + ag.huc8+
  forst.huc8 + elevation + seaDist + 
  monthly.precip.median + 
  NOT_OWEB_OWRI.wq.TotalCash + 
  OWEB_Grant_All_36_WC + 
  OWEB_Grant_All_36_SWCD + 
  OWEB_Grant_All_36_WC:OWEB_Grant_All_36_SWCD +
  f(HUC8,model='iid')+ f(total.period,model='rw2') + f(seasonal,model='seasonal',season.length=12)+ 
  f(s, model=spde.a,
    extraconstr = list(A = as.matrix(t(Q)%*%A.1), e= rep(0,n.covariates)))


mod.all.36m <- inla(form_all_36m, family='gaussian', data=inla.stack.data(stk.1),
                    control.predictor=list(A=inla.stack.A(stk.1), compute=TRUE),
                    #  control.inla=list(strategy='laplace'), 
                    control.compute=list(dic=TRUE, cpo=TRUE),verbose=T)

# put all the covariates (and the intercept) in a ``design matrix'' and make the matrix for the regression problem.  Using a QR factorisation for stability (don't worry!) the regression coefficients would be t(Q)%*%(spde)
X = cbind(rep(1,n.data),
          covars$Ag, covars$Forst,
          covars$Dev, covars$dev.huc8,
          covars$ag.huc8, covars$forst.huc8,
          covars$seaDist, covars$elevation,
          covars$monthly.precip.median, covars$NOT_OWEB_OWRI.wq.TotalCash,
          covars$OWEB_Grant_All_60_WC,
          covars$OWEB_Grant_All_60_SWCD,
          covars$OWEB_Grant_All_60_WC*covars$OWEB_Grant_All_60_SWCD,
          covars$HUC8, covars$total.period,covars$seasonal)
n.covariates = ncol(X)
Q = qr.Q(qr(X))


form_all_60m <-  y ~ 0 + b0 + Ag + Forst + Dev  + 
  dev.huc8 + ag.huc8+
  forst.huc8 + elevation + seaDist + 
  monthly.precip.median + 
  NOT_OWEB_OWRI.wq.TotalCash + 
  OWEB_Grant_All_60_WC + 
  OWEB_Grant_All_60_SWCD + 
  OWEB_Grant_All_60_WC:OWEB_Grant_All_60_SWCD +
  f(HUC8,model='iid')+ f(total.period,model='rw2') + f(seasonal,model='seasonal',season.length=12)+ 
  f(s, model=spde.a,
    extraconstr = list(A = as.matrix(t(Q)%*%A.1), e= rep(0,n.covariates)))


mod.all.60m <- inla(form_all_60m, family='gaussian', data=inla.stack.data(stk.1),
                    control.predictor=list(A=inla.stack.A(stk.1), compute=TRUE),
                    #  control.inla=list(strategy='laplace'), 
                    control.compute=list(dic=TRUE, cpo=TRUE),verbose=T)


tempcoef1 = data.frame(exp(mod.all.12m$summary.fixed[-1,c(1,3,5)]))
tempcoef2 = data.frame(exp(mod.all.36m$summary.fixed[-1,c(1,3,5)]))
tempcoef3 = data.frame(exp(mod.all.60m$summary.fixed[-1,c(1,3,5)]))

rowname.vector = 
  c(
    "$\\%$  Agric. (100m buffer)",
    '$\\%$  Forest (100m buffer)',
    '$\\%$  Devel. (100m buffer)',
    '$\\%$  Devel. in HUC8',
    "$\\%$  Agric. in HUC8",
    '$\\%$  Forest in HUC8',
    'Elevation (10m)',
    'Dist. from coast (10km)',
    'Monthly precip.',
    'Total Non-OWEB Restoration',
    'OWEB to WC (\\$100k)',
    'OWEB to SWCD (\\$100k)',
    'OWEB to WC * to OWEB (\\$100k)')


mod.all.12m = texreg::createTexreg(
  coef.names = rowname.vector,
  coef = tempcoef1[,1],
  ci.low = tempcoef1[,2],
  ci.up = tempcoef1[,3],
  gof.names = 'DIC',
  gof = mod.all.12m$dic$dic)

mod.all.36m = texreg::createTexreg(
  coef.names = rowname.vector,
  coef = tempcoef2[,1],
  ci.low = tempcoef2[,2],
  ci.up = tempcoef2[,3],
  gof.names = 'DIC',
  gof = mod.all.36m$dic$dic)

mod.all.60m = texreg::createTexreg(
  coef.names = rowname.vector,
  coef = tempcoef3[,1],
  ci.low = tempcoef3[,2],
  ci.up = tempcoef3[,3],
  gof.names = 'DIC',
  gof = mod.all.60m$dic$dic)


texreg(l = list(mod.all.12m,mod.all.36m,mod.all.60m),
       stars=numeric(0),ci.test = 1,digits = 3,
       custom.model.names = c('Past 12 months','Past 36 months','Past 60 months'),
       caption.above=T,omit.coef = "(100m)|(HUC8)|(10m)|(10km)|Total",
       label = c('table:allfunding'),
       custom.note = "$^* 1$ outside the credible interval",
       file='/homes/tscott1/win/user/quinalt/JPART_Submission/Version2/allfunding.tex')

##########Project type funding###############

# put all the covariates (and the intercept) in a ``design matrix'' and make the matrix for the regression problem.  Using a QR factorisation for stability (don't worry!) the regression coefficients would be t(Q)%*%(spde)
X = cbind(rep(1,n.data),
          covars$Ag, covars$Forst,
          covars$Dev, covars$dev.huc8,
          covars$ag.huc8, covars$forst.huc8,
          covars$seaDist, covars$elevation,
          covars$monthly.precip.median, covars$NOT_OWEB_OWRI.wq.TotalCash,
          covars$OWEB_Grant_Outreach_12_WC,
          covars$OWEB_Grant_Tech_12_WC, 
          covars$OWEB_Grant_Capacity_12_WC, 
          covars$OWEB_Grant_Restoration_12_WC, 
          covars$OWEB_Grant_Outreach_12_SWCD, 
          covars$OWEB_Grant_Tech_12_SWCD,
          covars$OWEB_Grant_Capacity_12_SWCD, 
          covars$OWEB_Grant_Restoration_12_SWCD, 
          covars$OWEB_Grant_Outreach_12_WC*covars$OWEB_Grant_Tech_12_WC*covars$OWEB_Grant_Capacity_12_WC*covars$OWEB_Grant_Restoration_12_WC, 
          covars$OWEB_Grant_Outreach_12_SWCD*covars$OWEB_Grant_Tech_12_SWCD*covars$OWEB_Grant_Capacity_12_SWCD*covars$OWEB_Grant_Restoration_12_SWCD,
          covars$HUC8, covars$total.period,covars$seasonal)
n.covariates = ncol(X)
Q = qr.Q(qr(X))


form_ind_12m <-  y ~ 0 + b0 + Ag + Forst + Dev  + 
  dev.huc8 + ag.huc8+
  forst.huc8 + elevation + seaDist + 
  monthly.precip.median + 
  NOT_OWEB_OWRI.wq.TotalCash + 
  OWEB_Grant_Outreach_12_WC + 
  OWEB_Grant_Tech_12_WC + 
  OWEB_Grant_Capacity_12_WC + 
  OWEB_Grant_Restoration_12_WC + 
  OWEB_Grant_Outreach_12_SWCD + 
  OWEB_Grant_Tech_12_SWCD + 
  OWEB_Grant_Capacity_12_SWCD + 
  OWEB_Grant_Restoration_12_SWCD + 
  OWEB_Grant_Outreach_12_WC:OWEB_Grant_Tech_12_WC:OWEB_Grant_Capacity_12_WC:OWEB_Grant_Restoration_12_WC + 
  OWEB_Grant_Outreach_12_SWCD:OWEB_Grant_Tech_12_SWCD:OWEB_Grant_Capacity_12_SWCD:OWEB_Grant_Restoration_12_SWCD + 
  f(HUC8,model='iid')+ f(total.period,model='rw2') + f(seasonal,model='seasonal',season.length=12)+ 
  f(s, model=spde.a,
    extraconstr = list(A = as.matrix(t(Q)%*%A.1), e= rep(0,n.covariates)))



# put all the covariates (and the intercept) in a ``design matrix'' and make the matrix for the regression problem.  Using a QR factorisation for stability (don't worry!) the regression coefficients would be t(Q)%*%(spde)
X = cbind(rep(1,n.data),
          covars$Ag, covars$Forst,
          covars$Dev, covars$dev.huc8,
          covars$ag.huc8, covars$forst.huc8,
          covars$seaDist, covars$elevation,
          covars$monthly.precip.median, covars$NOT_OWEB_OWRI.wq.TotalCash,
          covars$OWEB_Grant_Outreach_36_WC,
          covars$OWEB_Grant_Tech_36_WC, 
          covars$OWEB_Grant_Capacity_36_WC, 
          covars$OWEB_Grant_Restoration_36_WC, 
          covars$OWEB_Grant_Outreach_36_SWCD, 
          covars$OWEB_Grant_Tech_36_SWCD,
          covars$OWEB_Grant_Capacity_36_SWCD, 
          covars$OWEB_Grant_Restoration_36_SWCD, 
          covars$OWEB_Grant_Outreach_36_WC*covars$OWEB_Grant_Tech_36_WC*covars$OWEB_Grant_Capacity_36_WC*covars$OWEB_Grant_Restoration_36_WC, 
          covars$OWEB_Grant_Outreach_36_SWCD*covars$OWEB_Grant_Tech_36_SWCD*covars$OWEB_Grant_Capacity_36_SWCD*covars$OWEB_Grant_Restoration_36_SWCD,
          covars$HUC8, covars$total.period,covars$seasonal)
n.covariates = ncol(X)
Q = qr.Q(qr(X))

form_ind_36m <-  y ~ 0 + b0 + Ag + Forst + Dev  + 
  dev.huc8 + ag.huc8+
  forst.huc8 + elevation + seaDist + 
  monthly.precip.median + 
  NOT_OWEB_OWRI.wq.TotalCash + 
  OWEB_Grant_Outreach_36_WC + 
  OWEB_Grant_Tech_36_WC + 
  OWEB_Grant_Capacity_36_WC + 
  OWEB_Grant_Restoration_36_WC + 
  OWEB_Grant_Outreach_36_SWCD + 
  OWEB_Grant_Tech_36_SWCD + 
  OWEB_Grant_Capacity_36_SWCD + 
  OWEB_Grant_Restoration_36_SWCD + 
  OWEB_Grant_Outreach_36_WC:OWEB_Grant_Tech_36_WC:OWEB_Grant_Capacity_36_WC:OWEB_Grant_Restoration_36_WC + 
  OWEB_Grant_Outreach_36_SWCD:OWEB_Grant_Tech_36_SWCD:OWEB_Grant_Capacity_36_SWCD:OWEB_Grant_Restoration_36_SWCD + 
  f(HUC8,model='iid')+ f(total.period,model='rw2') + f(seasonal,model='seasonal',season.length=36)+ 
  f(s, model=spde.a,
    extraconstr = list(A = as.matrix(t(Q)%*%A.1), e= rep(0,n.covariates)))


# put all the covariates (and the intercept) in a ``design matrix'' and make the matrix for the regression problem.  Using a QR factorisation for stability (don't worry!) the regression coefficients would be t(Q)%*%(spde)
X = cbind(rep(1,n.data),
          covars$Ag, covars$Forst,
          covars$Dev, covars$dev.huc8,
          covars$ag.huc8, covars$forst.huc8,
          covars$seaDist, covars$elevation,
          covars$monthly.precip.median, covars$NOT_OWEB_OWRI.wq.TotalCash,
          covars$OWEB_Grant_Outreach_60_WC,
          covars$OWEB_Grant_Tech_60_WC, 
          covars$OWEB_Grant_Capacity_60_WC, 
          covars$OWEB_Grant_Restoration_60_WC, 
          covars$OWEB_Grant_Outreach_60_SWCD, 
          covars$OWEB_Grant_Tech_60_SWCD,
          covars$OWEB_Grant_Capacity_60_SWCD, 
          covars$OWEB_Grant_Restoration_60_SWCD, 
          covars$OWEB_Grant_Outreach_60_WC*covars$OWEB_Grant_Tech_60_WC*covars$OWEB_Grant_Capacity_60_WC*covars$OWEB_Grant_Restoration_60_WC, 
          covars$OWEB_Grant_Outreach_60_SWCD*covars$OWEB_Grant_Tech_60_SWCD*covars$OWEB_Grant_Capacity_60_SWCD*covars$OWEB_Grant_Restoration_60_SWCD,
          covars$HUC8, covars$total.period,covars$seasonal)
n.covariates = ncol(X)
Q = qr.Q(qr(X))

form_ind_60m <-  y ~ 0 + b0 + Ag + Forst + Dev  + 
  dev.huc8 + ag.huc8+
  forst.huc8 + elevation + seaDist + 
  monthly.precip.median + 
  NOT_OWEB_OWRI.wq.TotalCash + 
  OWEB_Grant_Outreach_60_WC + 
  OWEB_Grant_Tech_60_WC + 
  OWEB_Grant_Capacity_60_WC + 
  OWEB_Grant_Restoration_60_WC + 
  OWEB_Grant_Outreach_60_SWCD + 
  OWEB_Grant_Tech_60_SWCD + 
  OWEB_Grant_Capacity_60_SWCD + 
  OWEB_Grant_Restoration_60_SWCD + 
  OWEB_Grant_Outreach_60_WC:OWEB_Grant_Tech_60_WC:OWEB_Grant_Capacity_60_WC:OWEB_Grant_Restoration_60_WC + 
  OWEB_Grant_Outreach_60_SWCD:OWEB_Grant_Tech_60_SWCD:OWEB_Grant_Capacity_60_SWCD:OWEB_Grant_Restoration_60_SWCD + 
  f(HUC8,model='iid')+ f(total.period,model='rw2') + f(seasonal,model='seasonal',season.length=60)+ 
  f(s, model=spde.a,
    extraconstr = list(A = as.matrix(t(Q)%*%A.1), e= rep(0,n.covariates)))

mod.ind.12m <- inla(form_ind_12m, family='gaussian', data=inla.stack.data(stk.1),
                    control.predictor=list(A=inla.stack.A(stk.1), compute=TRUE),
                    #  control.inla=list(strategy='laplace'), 
                    control.compute=list(dic=TRUE, cpo=TRUE),verbose=T, control.inla = list(correct = TRUE, correct.factor = 10))

mod.ind.36m <- inla(form_ind_36m, family='gaussian', data=inla.stack.data(stk.1),
                    control.predictor=list(A=inla.stack.A(stk.1), compute=TRUE),
                    #  control.inla=list(strategy='laplace'), 
                    control.compute=list(dic=TRUE, cpo=TRUE),verbose=T, control.inla = list(correct = TRUE, correct.factor = 10))

mod.ind.60m <- inla(form_ind_60m, family='gaussian', data=inla.stack.data(stk.1),
                    control.predictor=list(A=inla.stack.A(stk.1), compute=TRUE),
                    #  control.inla=list(strategy='laplace'), 
                    control.compute=list(dic=TRUE, cpo=TRUE),verbose=T, control.inla = list(correct = TRUE, correct.factor = 10))

tempcoef1 = data.frame(exp(mod.ind.12m$summary.fixed[-1,c(1,3,5)]))
tempcoef2 = data.frame(exp(mod.ind.36m$summary.fixed[-1,c(1,3,5)]))
tempcoef3 = data.frame(exp(mod.ind.60m$summary.fixed[-1,c(1,3,5)]))

rownames(tempcoef1) = rownames(tempcoef2) = rownames(tempcoef3) =  
  c(
    "$\\%$  Agric. (100m buffer)",
    '$\\%$  Forest (100m buffer)',
    '$\\%$  Devel. (100m buffer)',
    '$\\%$  Devel. in HUC8',
    "$\\%$  Agric. in HUC8",
    '$\\%$  Forest in HUC8',
    'Elevation (10m)',
    'Dist. from coast (10km)',
    'Monthly precip.',
    'Total Non-OWEB Restoration',
    "WC Outreach",
    'WC Tech',
    'WC Capacity',
    'WC Restoration',
    "SWCD Outreach",
    'SWCD Tech',
    'SWCD Capacity',
    'SWCD Restoration',
    'WC 4-Way Interaction',
    'SWCD 4-Way Interaction')


mod.ind.12m = texreg::createTexreg(
  coef.names = rownames(tempcoef1),
  coef = tempcoef1[,1],
  ci.low = tempcoef1[,2],
  ci.up = tempcoef1[,3],
  gof.names = 'DIC',
  gof = mod.ind.12m$dic$dic)

mod.ind.36m = texreg::createTexreg(
  coef.names = rownames(tempcoef2),
  coef = tempcoef2[,1],
  ci.low = tempcoef2[,2],
  ci.up = tempcoef2[,3],
  gof.names = 'DIC',
  gof = mod.ind.36m$dic$dic)

mod.ind.60m = texreg::createTexreg(
  coef.names = rownames(tempcoef3),
  coef = tempcoef3[,1],
  ci.low = tempcoef3[,2],
  ci.up = tempcoef3[,3],
  gof.names = 'DIC',
  gof = mod.ind.60m$dic$dic)


texreg(l = list(mod.ind.12m,mod.ind.36m,mod.ind.60m),
       stars=numeric(0),ci.test = 1,digits = 3,
       custom.model.names = c('Past 12 months','Past 36 months','Past 60 months'),
       caption.above=T,omit.coef = "(100m)|(HUC8)|(10m)|(10km)|Total|precip",
       label = c('table:typefunding'),
       caption = 'Predicted water quality impact by grant type',
       custom.note = "$^* 1$ outside the credible interval",
       file='/homes/tscott1/win/user/quinalt/JPART_Submission/Version2/typefunding.tex')



##########Capacity Building#############


# put all the covariates (and the intercept) in a ``design matrix'' and make the matrix for the regression problem.  Using a QR factorisation for stability (don't worry!) the regression coefficients would be t(Q)%*%(spde)
X = cbind(rep(1,n.data),
          covars$Ag, covars$Forst,
          covars$Dev, covars$dev.huc8,
          covars$ag.huc8, covars$forst.huc8,
          covars$seaDist, covars$elevation,
          covars$monthly.precip.median, covars$NOT_OWEB_OWRI.wq.TotalCash,
          covars$OWEB_Grant_Outreach_12_WC, 
            covars$OWEB_Grant_Tech_12_WC,
            covars$OWEB_Grant_Restoration_12_WC,
            covars$OWEB_Grant_Capacity_PriorTo12, 
            covars$OWEB_Grant_Capacity_PriorTo12*covars$OWEB_Grant_Outreach_12_WC,
            covars$OWEB_Grant_Capacity_PriorTo12*covars$OWEB_Grant_Tech_12_WC,
            covars$OWEB_Grant_Capacity_PriorTo12*covars$OWEB_Grant_Restoration_12_WC, 
            covars$OWEB_Grant_Capacity_PriorTo12*covars$OWEB_Grant_Outreach_12_WC*covars$OWEB_Grant_Tech_12_WC*covars$OWEB_Grant_Capacity_12_WC*covars$OWEB_Grant_Restoration_12_WC, 
          covars$HUC8, covars$total.period,covars$seasonal)
n.covariates = ncol(X)
Q = qr.Q(qr(X))


form_cap_12m <-  y ~ 0 + b0 + Ag + Forst + Dev  + 
  dev.huc8 + ag.huc8+
  forst.huc8 + elevation + seaDist + 
  monthly.precip.median + 
  NOT_OWEB_OWRI.wq.TotalCash + 
  OWEB_Grant_Outreach_12_WC + 
  OWEB_Grant_Tech_12_WC + 
  OWEB_Grant_Restoration_12_WC + 
  OWEB_Grant_Capacity_PriorTo12 + 
  OWEB_Grant_Capacity_PriorTo12:OWEB_Grant_Outreach_12_WC + 
  OWEB_Grant_Capacity_PriorTo12:OWEB_Grant_Tech_12_WC + 
  OWEB_Grant_Capacity_PriorTo12:OWEB_Grant_Restoration_12_WC + 
  OWEB_Grant_Capacity_PriorTo12:OWEB_Grant_Outreach_12_WC:OWEB_Grant_Tech_12_WC:OWEB_Grant_Capacity_12_WC:OWEB_Grant_Restoration_12_WC + 
  f(HUC8,model='iid')+ f(total.period,model='rw2') + f(seasonal,model='seasonal',season.length=12)+ 
  f(s, model=spde.a,replicate=s.repl)



# put all the covariates (and the intercept) in a ``design matrix'' and make the matrix for the regression problem.  Using a QR factorisation for stability (don't worry!) the regression coefficients would be t(Q)%*%(spde)
X = cbind(rep(1,n.data),
          covars$Ag, covars$Forst,
          covars$Dev, covars$dev.huc8,
          covars$ag.huc8, covars$forst.huc8,
          covars$seaDist, covars$elevation,
          covars$monthly.precip.median, covars$NOT_OWEB_OWRI.wq.TotalCash,
          covars$OWEB_Grant_Outreach_36_WC, 
          covars$OWEB_Grant_Tech_36_WC,
          covars$OWEB_Grant_Restoration_36_WC,
          covars$OWEB_Grant_Capacity_PriorTo36, 
          covars$OWEB_Grant_Capacity_PriorTo36*covars$OWEB_Grant_Outreach_36_WC,
          covars$OWEB_Grant_Capacity_PriorTo36*covars$OWEB_Grant_Tech_36_WC,
          covars$OWEB_Grant_Capacity_PriorTo36*covars$OWEB_Grant_Restoration_36_WC, 
          covars$OWEB_Grant_Capacity_PriorTo36*covars$OWEB_Grant_Outreach_36_WC*covars$OWEB_Grant_Tech_36_WC*covars$OWEB_Grant_Capacity_36_WC*covars$OWEB_Grant_Restoration_36_WC, 
          covars$HUC8, covars$total.period,covars$seasonal)
n.covariates = ncol(X)
Q = qr.Q(qr(X))

form_cap_36m <-  y ~ 0 + b0 + Ag + Forst + Dev  + 
  dev.huc8 + ag.huc8+
  forst.huc8 + elevation + seaDist + 
  monthly.precip.median + 
  NOT_OWEB_OWRI.wq.TotalCash + 
  OWEB_Grant_Outreach_36_WC + 
  OWEB_Grant_Tech_36_WC + 
  OWEB_Grant_Restoration_36_WC + 
  OWEB_Grant_Capacity_PriorTo36 + 
  OWEB_Grant_Capacity_PriorTo36:OWEB_Grant_Outreach_36_WC + 
  OWEB_Grant_Capacity_PriorTo36:OWEB_Grant_Tech_36_WC + 
  OWEB_Grant_Capacity_PriorTo36:OWEB_Grant_Restoration_36_WC + 
  OWEB_Grant_Capacity_PriorTo36:OWEB_Grant_Outreach_36_WC:OWEB_Grant_Tech_36_WC:OWEB_Grant_Capacity_36_WC:OWEB_Grant_Restoration_36_WC + 
  f(HUC8,model='iid')+ f(total.period,model='rw2') + f(seasonal,model='seasonal',season.length=12)+ 
  f(s, model=spde.a,replicate=s.repl)



# put all the covariates (and the intercept) in a ``design matrix'' and make the matrix for the regression problem.  Using a QR factorisation for stability (don't worry!) the regression coefficients would be t(Q)%*%(spde)
X = cbind(rep(1,n.data),
          covars$Ag, covars$Forst,
          covars$Dev, covars$dev.huc8,
          covars$ag.huc8, covars$forst.huc8,
          covars$seaDist, covars$elevation,
          covars$monthly.precip.median, covars$NOT_OWEB_OWRI.wq.TotalCash,
          covars$OWEB_Grant_Outreach_60_WC, 
          covars$OWEB_Grant_Tech_60_WC,
          covars$OWEB_Grant_Restoration_60_WC,
          covars$OWEB_Grant_Capacity_PriorTo60, 
          covars$OWEB_Grant_Capacity_PriorTo60*covars$OWEB_Grant_Outreach_60_WC,
          covars$OWEB_Grant_Capacity_PriorTo60*covars$OWEB_Grant_Tech_60_WC,
          covars$OWEB_Grant_Capacity_PriorTo60*covars$OWEB_Grant_Restoration_60_WC, 
          covars$OWEB_Grant_Capacity_PriorTo60*covars$OWEB_Grant_Outreach_60_WC*covars$OWEB_Grant_Tech_60_WC*covars$OWEB_Grant_Capacity_60_WC*covars$OWEB_Grant_Restoration_60_WC, 
          covars$HUC8, covars$total.period,covars$seasonal)
n.covariates = ncol(X)
Q = qr.Q(qr(X))


form_cap_60m <-  y ~ 0 + b0 + Ag + Forst + Dev  + 
  dev.huc8 + ag.huc8+
  forst.huc8 + elevation + seaDist + 
  monthly.precip.median + 
  NOT_OWEB_OWRI.wq.TotalCash + 
  OWEB_Grant_Outreach_60_WC + 
  OWEB_Grant_Tech_60_WC + 
  OWEB_Grant_Restoration_60_WC + 
  OWEB_Grant_Capacity_PriorTo60 + 
  OWEB_Grant_Capacity_PriorTo60:OWEB_Grant_Outreach_60_WC + 
  OWEB_Grant_Capacity_PriorTo60:OWEB_Grant_Tech_60_WC + 
  OWEB_Grant_Capacity_PriorTo60:OWEB_Grant_Restoration_60_WC + 
  OWEB_Grant_Capacity_PriorTo60:OWEB_Grant_Outreach_60_WC:OWEB_Grant_Tech_60_WC:OWEB_Grant_Capacity_60_WC:OWEB_Grant_Restoration_60_WC + 
  f(HUC8,model='iid')+ f(total.period,model='rw2') + f(seasonal,model='seasonal',season.length=12)+ 
  f(s, model=spde.a,replicate=s.repl)


mod.cap.12m <- inla(form_cap_12m, family='gaussian', data=inla.stack.data(stk.1),
                    control.predictor=list(A=inla.stack.A(stk.1), compute=TRUE),
                    #  control.inla=list(strategy='laplace'), 
                    control.compute=list(dic=TRUE, cpo=TRUE),verbose=T, control.inla = list(correct = TRUE, correct.factor = 10))

mod.cap.36m <- inla(form_cap_36m, family='gaussian', data=inla.stack.data(stk.1),
                    control.predictor=list(A=inla.stack.A(stk.1), compute=TRUE),
                    #  control.inla=list(strategy='laplace'), 
                    control.compute=list(dic=TRUE, cpo=TRUE),verbose=T, control.inla = list(correct = TRUE, correct.factor = 10))

mod.cap.60m <- inla(form_cap_60m, family='gaussian', data=inla.stack.data(stk.1),
                    control.predictor=list(A=inla.stack.A(stk.1), compute=TRUE),
                    #  control.inla=list(strategy='laplace'), 
                    control.compute=list(dic=TRUE, cpo=TRUE),verbose=T, control.inla = list(correct = TRUE, correct.factor = 10))

tempcoef1 = data.frame(exp(mod.cap.12m$summary.fixed[-1,c(1,3,5)]))
tempcoef2 = data.frame(exp(mod.cap.36m$summary.fixed[-1,c(1,3,5)]))
tempcoef3 = data.frame(exp(mod.cap.60m$summary.fixed[-1,c(1,3,5)]))

rownames(tempcoef1) = rownames(tempcoef2) = rownames(tempcoef3) =  
  c(
    "$\\%$  Agric. (100m buffer)",
    '$\\%$  Forest (100m buffer)',
    '$\\%$  Devel. (100m buffer)',
    '$\\%$  Devel. in HUC8',
    "$\\%$  Agric. in HUC8",
    '$\\%$  Forest in HUC8',
    'Elevation (10m)',
    'Dist. from coast (10km)',
    'Monthly precip.',
    'Total Non-OWEB Restoration',
    "WC Outreach",
    'WC Tech',
    'WC Restoration',
    'Prior Capacity',
    "Prior Capacity * WC Outreach",
    'Prior Capacity * WC Tech',
    'Prior Capacity * WC Restoration',
    'Prior Capacity * Outreach * Tech * Restoration')


mod.cap.12m = texreg::createTexreg(
  coef.names = rownames(tempcoef1),
  coef = tempcoef1[,1],
  ci.low = tempcoef1[,2],
  ci.up = tempcoef1[,3],
  gof.names = 'DIC',
  gof = mod.cap.12m$dic$dic)

mod.cap.36m = texreg::createTexreg(
  coef.names = rownames(tempcoef2),
  coef = tempcoef2[,1],
  ci.low = tempcoef2[,2],
  ci.up = tempcoef2[,3],
  gof.names = 'DIC',
  gof = mod.cap.36m$dic$dic)

mod.cap.60m = texreg::createTexreg(
  coef.names = rownames(tempcoef3),
  coef = tempcoef3[,1],
  ci.low = tempcoef3[,2],
  ci.up = tempcoef3[,3],
  gof.names = 'DIC',
  gof = mod.cap.60m$dic$dic)


texreg(l = list(mod.cap.12m,mod.cap.36m,mod.cap.60m),
       stars=numeric(0),ci.test = 1,digits = 3,
       custom.model.names = c('Past 12 months','Past 36 months','Past 60 months'),
       caption.above=T,omit.coef = "(100m)|(HUC8)|(10m)|(10km)|Total|precip",
       label = c('table:capacityfunding'),
       caption = 'Predicted water quality impact conditional on past capacity building',
       custom.note = "$^* 1$ outside the credible interval",
       file='/homes/tscott1/win/user/quinalt/JPART_Submission/Version2/capacitybuilding.tex')

mail::sendmail('tyler.andrew.scott@gmail.com','run_models.R finished','nori has finished quinalt project data prep (with precip)')
