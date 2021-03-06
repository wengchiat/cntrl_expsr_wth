library(lubridate)
library(dplyr)
library(tidyr)
library(zoo)
library(ggplot2)
startdate <- ymd('2014-05-01')
enddate <- ymd('2018-05-01')


data <- data %>% 
    mutate(Birth.Date = dmy(Birth.Date),
           Hire.Date = dmy(Hire.Date),
           Terminate.Date = dmy(Terminate.Date), 
           is.term = ifelse(!is.na(Terminate.Date), 1, 0 )) %>% 
    replace_na(list(Terminate.Date = enddate)) %>% 
    mutate(SVC = decimal_date(Terminate.Date) - 
               decimal_date(as.Date(sapply(Hire.Date, max, startdate))))

agg_exp <- matrix(rep(0,10000), nrow = 100, ncol = 100)
agg_term <- matrix(rep(0,10000), nrow = 100, ncol = 100)

for (id in 1:dim(data)[1]){
    #id <- 21#which(data$Employee. == '461789') #120
    termdate <- data[id, "Terminate.Date"]
    is.term <- !is.na(termdate)
    termdate <- replace_na(termdate, enddate)
    
    hiredate <- data[id, "Hire.Date"]
    birthdate <- data[id, "Birth.Date"]
    
    svcend <- decimal_date(min(termdate, enddate)) - decimal_date(hiredate) 
    svcstart <- max(0, decimal_date(startdate) - decimal_date(hiredate))
    ageend <- decimal_date(min(termdate, enddate)) - decimal_date(birthdate) 
    agestart <- decimal_date(max(hiredate, startdate)) - decimal_date(birthdate)
    
    if (floor(agestart) == floor(ageend)){
        exposure_age <- floor(agestart)
        g = ageend - agestart
    } else {
        exposure_age <- seq(floor(agestart), floor(ageend), 1)
        a <- exposure_age + 1 - agestart 
        b <- ageend - exposure_age
        g <- (a < 1) * a + (b < 1) * b 
        if (g[length(g)] == 0 ){g <- g[-length(g)]}
        g <- (g == 0) * (g == 0) * 1 + g
    }
    if (floor(svcstart) == floor(svcend)){
        exposure_svc <- floor(svcstart)
        h = svcend - svcstart
        
    } else {
        exposure_svc <- seq(floor(svcstart), floor(svcend), 1)
        c <- exposure_svc + 1 - svcstart 
        d <- svcend - exposure_svc
        h <- (c < 1) * c + (d < 1) * d
        if (h[length(h)] == 0 ){h <- h[-length(h)]}
        h <- (h == 0) * (h == 0) * 1 + h
    }

    if (is.term){
        agg_term[floor(ageend) + 1,
                 floor(svcend) + 1] <- agg_term[floor(ageend) + 1,
                                                floor(svcend) + 1] + 1 
    }

    f <- matrix(rep(0,10000), nrow = 100, ncol = 100)
    rowStart <- floor(agestart) + 1
    colStart <- floor(svcstart) + 1
    
    nRow <- max(length(g),length(h))
    
    if(g[1] <= h[1]){
        for (i in 0:(nRow-1)){
            f[rowStart + i, colStart + i] = g[i + 1] - sum(f[rowStart + i,])
            if(!is.na(h[i + 1])){
                f[rowStart + i + 1, colStart + i] = h[i + 1] - f[rowStart + i, colStart + i]
            }
        }
    } else {
        for (i in 0:(nRow-1)){
            f[rowStart + i, colStart + i] = h[i + 1] - sum(f[,colStart + i])
            if(!is.na(g[i + 1])){
                f[rowStart + i, colStart + i + 1] = g[i + 1] - f[rowStart + i, colStart + i]
            }
        }
    }
    agg_exp <- agg_exp + f       
#    if(sum(f) > 0){
#        if(sum(colSums(f)[colSums(f)>0] == h) == 0){print(id)} 
#        if(sum(rowSums(f)[rowSums(f)>0] == g) == 0){print(id)}
    
 #   if (is.na(sum(f))){print(id)}
    if (sum(g) != data[id, 'SVC']){print(id)}
    if (sum(h) != data[id, 'SVC']){print(id)}
    
}
age_exposure <- rowSums(agg_exp[1:60,])
age_term <- rowSums(agg_term[1:60,])
term_all = age_term/age_exposure
term_all

age_exposure <- rowSums(agg_exp[1:60,-1])
age_term <- rowSums(agg_term[1:60,-1])
term_1 = age_term/age_exposure
term_1
age_exposure <- rowSums(agg_exp[1:60,-c(1,2)])
age_term <- rowSums(agg_term[1:60,-c(1,2)])
term_2 = age_term/age_exposure

plot(term_all, pch = 19) 
points(term_1, pch = 19, col = 'red')
points(term_2, pch = 19, col = 'blue')
lines(x = mywth$Age, y = mywth$MYWTH)

age_exposure <- rowSums(agg_exp[1:60,-1])
lwr <- term_1 - 1 * qnorm(0.975) * sqrt(term_1 * (1 - term_1) / age_exposure)
upr <- term_1 + 1 * qnorm(0.975) * sqrt(term_1 * (1 - term_1) / age_exposure)

plot(term_1, pch = 19, col = 'red')
lines(lwr)
lines(upr)
lines(x = mywth$Age, y = 1.5*mywth$MYWTH, col = 'blue')

age_exposure <- rowSums(agg_exp[1:60,-c(1,2)])
lwr <- term_2 - 1 * qnorm(0.975) * sqrt(term_2 * (1 - term_2) / age_exposure)
upr <- term_2 + 1 * qnorm(0.975) * sqrt(term_2 * (1 - term_2) / age_exposure)

for(fac in 100:200){
    print(fac)
    print(sum(term_1[20:60] - (1+fac/100) * mywth$MYWTH[5:45])^2)
}


plot(term_2, pch = 19, col = 'red')
lines(lwr)
lines(upr)
lines(x = mywth$Age, y = mywth$MYWTH, col = 'blue')




