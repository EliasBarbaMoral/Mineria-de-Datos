##Tarea final MD
# Elias Barba Moral
# Tratamiento de unos deatos referentes a semillas de trigo: 

##Primero cargamos los datos:
dataseeds <- read.table("C:/Users/Elias/Desktop/Zaragoza/MD/Tarea Final/data.txt", header=TRUE)
attach(dataseeds)
data_test$Tipo<-as.factor(data_test$Tipo)
data_train$Tipo<-as.factor(data_train$Tipo)

#Cargamos desde el principio todas las librerias a usar:
library(caret)
library(lattice)#density plot
library(psych)#cohen kappa
library(e1071)#Naive Bayes
library(klaR)
library(rattle)#arbol de rattle
library(rpart)#arbol normal
library(adabag)#boosting

##Analisis preliminar de los datos para la Introducci�n

##Busqueda outliers
cor(dataseeds)
pairs(dataseeds[,1:7])
plot(dataseeds[,1:8], col=as.numeric(Tipo))

##boxplots
par(mfrow=c(2,4))
for (i in 1:(length(dataseeds)-1)){
  boxplot(dataseeds[,i]~as.numeric(Tipo), data=dataseeds, main="Seeds Kernel Data", xlab="Seed Type", ylab=colnames(dataseeds)[i])
}
par(mfrow=c(1,1))

##Graficas de densidad del apendice A
densityplot( ~ Area, groups=dataseeds$Tipo, data=dataseeds)
densityplot( ~ Perim, groups=dataseeds$Tipo, data=dataseeds)
densityplot( ~ Compac, groups=dataseeds$Tipo, data=dataseeds)
densityplot( ~ Asim, groups=dataseeds$Tipo, data=dataseeds)
densityplot( ~ Ranura, groups=dataseeds$Tipo, data=dataseeds)
densityplot( ~ Largo, groups=dataseeds$Tipo, data=dataseeds)
densityplot( ~ Ancho, groups=dataseeds$Tipo, data=dataseeds)

##Analisis de componentes principales
princompdata<-princomp(dataseeds[, 1:7])
summary(princompdata)
princompdata$loadings
dataseedsPC <- predict(princomp(dataseeds[, 1:7]))
summary(dataseedsPC)
plot(dataseedsPC[, 1:2], col = as.numeric(Tipo))

##Separacion de los datos en validaci�n y entrenamiento:
set.seed(1234)
split=0.70
trainIndex <- createDataPartition(Tipo, p=split, list=FALSE)
data_train <- dataseeds[ trainIndex,]
data_test <- dataseeds[-trainIndex,]


##Primer clasificador: LDA
#Linear discriminant model
mod.lda <- lda(Tipo ~ ., data = data_train)
mod.lda
plot(mod.lda)

#Predicci�n con los datos de validaci�n
predictLDA <- predict(mod.lda, newdata = data_test)

#Matriz de confusi�n
conmat<-confusionMatrix(predictLDA$class,data_test$Tipo)
conmat

#Representaci�n gr�fica de los datos de validaci�n
dataseeds2<-cbind(data_test, predictLDA$x[,1:2])
partimat(Tipo ~LD2+LD1, data=dataseeds2, method="lda")


##Otros modelos de clasificaci�n, ap�ndice B:
#Quadratic discriminant model
mod.qda <- qda(Tipo ~ ., data = data_train)
mod.qda
predictQDA <- predict(mod.qda, newdata = data_test)
conmatlda<-confusionMatrix(predictQDA$class,data_test$Tipo)
conmatlda

#Naive Bayes
mod.NB <- naiveBayes(as.factor(Tipo) ~ ., data = data_train)
mod.NB
predictNB <- predict(mod.NB, newdata=data_test)
conmatnaive<-confusionMatrix(predictNB,data_test$Tipo)
conmatnaive

#K-NN Vecinos proximos:
trctrl <- trainControl(method = "repeatedcv", number = 10, repeats = 3)
mod.sknn <- train(Tipo~. , data = data_train, method = "knn", trControl=trctrl, preProcess = c("center", "scale"),tuneLength = 10)
mod.sknn
predictknn <- predict(mod.sknn, newdata=data_test)
conmatknn<-confusionMatrix(predictNB,data_test$Tipo)
conmatknn


##Segundo Clasificador: Arbol de clasificacion
#Construcci�n del �rbol con rpart
modeltree<-rpart(formula=Tipo~. ,data_train, method="class")
summary(modeltree)
plot(modeltree)
text(modeltree)

#Gr�fico de complejidad
plotcp(modeltree)

#�rbol con complejidad ajustada
mod.TREE<-rpart(Tipo~. ,data=data_train,method="class", cp=0.06)
summary(mod.TREE)
plot(mod.TREE)
text(mod.TREE)
data_test$Tipo<-as.factor(data_test$Tipo)
predict.tree<-predict(mod.TREE,newdata=data_test)
predict.tree

##Boosting
cntrl<-rpart.control(maxdepth = 1)
data.adaboost <- boosting(Tipo~., data=data_train, mfinal=500, control=cntrl)

data.predict<-predict.boosting(data.adaboost, newdata=data_test)
conmattree<-confusionMatrix(data.predict$class,data_test$Tipo)
conmattree

#Gr�fico de evoluci�n del error
evol.train<-errorevol(data.adaboost,data_train)
evol.test<-errorevol(data.adaboost,data_test)
plot(evol.test$error, type="l", ylim=c(0.01,0.4),  main="Adaboost error Vs number of trees",  xlab="Iterations", ylab="Error", col = "red")
lines(evol.train$error, cex = .5 ,col="blue", lty=2)
legend("topright", c("validacion","entrenamiento"), col = c("red", "blue"), lty=1:2)

#Importancia de las variables
rev(sort(data.adaboost$importance))
importanceplot(data.adaboost)

#Construcci�n del �rbol con rattle
rattle()
