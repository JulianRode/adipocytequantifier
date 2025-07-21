library(tidyverse);library(nls2);library(proto);library(minpack.lm);library(gridExtra);library(cowplot);library(svglite); library(ggpubr); rm(list=ls(all=TRUE)); set.seed(12345)
'Welcome,
Here you can create graphs based on the Adipocyte quantifier output.
Further instructions look like:'
#This


#Please paste the path to your .csv file in the following command. 
#If your path contains single \, please replace them with \\
look_up_path <- "Z:\\Lab members\\Students\\Julian (Msc Metabolism)\\Quantifications\\big images 30.07.24\\DDZ analyzed\\DDZ Area.csv"
#Where will your graph be saved?
#If your path contains single \, please replace them with \\
output_path <- "Z:\\Lab members\\Students\\Julian (Msc Metabolism)\\figures\\Everything anew"
#how do you want to label your graph?
graph_name <- "DDZ females GWAT"

#Which parts of the data do you want to display? 
#Add them to the vector in order of appearance on the graph
#display_order <- c("females, GWAT, CD, control", "females, GWAT, CD, mlkl", "females, GWAT, CD, mlkl casp-8","females, GWAT, CD, mlkl hoip casp-8")
display_order <- c("females, GWAT, CD, control", "females, GWAT, CD, casp-8", "females, GWAT, CD, hoip casp-8")

#How do you want to label the legend?
lab_list <- c("control", "casp-8KO", "Hoip;Casp-8KO")
#lab_list <- c("control", "MlklKO","MlklKO Casp-8A-KO", "MlklKO Hoip;Casp-8A-KO")

#customize display colours here (in order of appearance on the graph):
mousecolours <- c("grey", "blue", "#6D3F91") #colour scheme for mlkl in DDZ
#mousecolours <- c("grey", "#CDCD0F", "#8B8C21", "#CE860C") #colour scheme for hoip/casp-8
#now you are all set up. Hit ctrl + shift + enter to output your graph.










detections <- read.csv(look_up_path, header = TRUE, sep = ",", dec = ".")

#modifying the dataframe
detections$X <- NULL
rownames(detections) <- NULL

#which tissue is being used?
if(length(display_order)>0){
  usedetections <- detections[detections$Folders %in% display_order,]
}else{
  usedetections <- detections
}


usedetections <- usedetections %>% 
  mutate(Folders = factor(Folders, levels = display_order)) %>% 
  arrange(Folders)

ul <- unique(usedetections$Folders) #this sorts the later factors into the order supplied

#used for area and count graphs later
individual_mice <- separate(data = usedetections, col = Label, into = c("Mouse_name", "Addition"), sep = " ", remove = TRUE)

if(length(lab_list)==0){
  lab_list <- 1:length(display_order)
}

#creating binsizes and breaks for the upcoming histogram
quantiles <- c()
for(i in ul){
  quantiles[i] <- quantile(usedetections[usedetections$Folders==i,]$Area, 0.95)
}
quantile95 <- max(quantiles)
binsize <- ceiling(quantile95/2500)*250
upper_limit <- ceiling(quantile95/binsize)*binsize
breaks <- seq(from = -binsize/2, to = ceiling(max(usedetections[,]$Area)/binsize)*binsize+binsize/2, by = binsize)

#create custom binning of histogram
df <- data.frame()
for(i in ul){
  histos <- hist(usedetections$Area[usedetections$Folders==i], breaks = breaks,
                    include.lowest = TRUE, plot = FALSE,)
  mouse <- rep(i,length(histos$counts))
  data <- data.frame(mouse,head(histos$breaks,-1), histos$mids, histos$counts)
  df <- rbind(df, data)
}
colnames(df) <- c("mouse","breaks","mids", "counts")

#non-linear regression control
nlc <- nls.lm.control(maxiter = 1024)
#empty list to be filled with regression parameters
gaus_para <- list()
reg_gauss <- list()
mu <- list()
ampl <- list()
stddif <- list()

#creating gaussian regression for every different type of folder in df, adding the regression parameters to list to be called in ggplot
for(i in ul){
  x <- df[df$mouse==i,]$mids
  y <- df[df$mouse==i,]$counts
  gaus_para[[i]] <- nlsLM(formula = y~A*dnorm(x, mu, sd), 
                          start = list(A=10000000,mu=500,sd=1000),
                     jac = NULL, control = nlc
                     #lower = c(10000,-50000,500), upper = c(10000000000, 100000, 70000)
                     )
  mu[[i]] <- gaus_para[[i]]$m$getPars()[2]
  stddif[[i]] <- gaus_para[[i]]$m$getPars()[3]
  ampl[[i]] <- gaus_para[[i]]$m$getPars()[1]
  reg_gauss[[i]] <- function(x, A, mean, sd){
    y=A*dnorm(x, mean = mean,sd = sd)
  }
}

#insert kolmogorov-smirnov squared test of df
#first create a dataframe with one column for the distribution of every type of mouse
stat_df <- data.frame(matrix(,nrow=length(histos$counts),ncol=0))
for(i in ul){
  stat_df <- cbind(stat_df, df[df$mouse==i,]$counts)
}
colnames(stat_df) <- unique(usedetections$Folders)
rownames(stat_df) <- histos$mids

#now test distributions

kolmogorov <- list()
for(i in 2:length(ul)){
  kolmogorov[[i]] <- ks.test(usedetections[usedetections$Folders==ul[1],]$Area,usedetections[usedetections$Folders==ul[i],]$Area)
  if(kolmogorov[[i]]$p.value==0){
    kolmogorov[[i]]$p.value <- 2.2e-16
  }
  #lab_list[i] <- paste(lab_list[i], as.character(format(kolmogorov[[i]]$p.value, scientific = TRUE, digits = 3)), sep = " ")
}

#creating display dataframe again with all values outside of range added to largest value; so essentially cropping the data
usedetections$Area[usedetections$Area>upper_limit] <- upper_limit
breaks <- seq(from = -binsize/2, to = upper_limit+binsize/2, by = binsize)
df <- data.frame()

for(i in ul){
  histos1 <- hist(usedetections$Area[usedetections$Folders==i], breaks = breaks,
                 include.lowest = TRUE, plot = FALSE,)
  mouse <- rep(i,length(histos1$counts))
  data <- data.frame(mouse,head(histos1$breaks,-1), histos1$mids, histos1$counts)
  df <- rbind(df, data)
}
colnames(df) <- c("mouse","breaks","mids", "counts")

tick_labels <- histos1$mids
tick_labels[1] <- paste("<", binsize/2, sep = "")
tick_labels[length(tick_labels)] <- paste(">", upper_limit, sep = "")


#create plot of histogram
histoplot <- df %>% 
  mutate(mouse = fct_relevel(mouse, levels(ul))) %>% 
ggplot() + 
  geom_col(aes(mids, counts, fill = mouse), position = position_dodge2(width = 0.9, padding = 0.2), color = "black", size = 0.25) +
  xlim(-binsize/2, upper_limit+binsize/2) + 
  ggtitle(graph_name) + 
  theme(legend.title = NULL,
    text = element_text(size = 9),
    panel.background = element_rect(fill = "transparent",colour = NA),
    axis.line = element_line(colour = "black"),
    validate = TRUE,
    strip.background = element_rect(fill = "white"),
    legend.position = "bottom",
    legend.key.size = unit(0.5, "line"),
    line = element_line(linewidth = 0.25),
    legend.box.spacing = unit(0.1, "line")) + 
  scale_fill_manual(values = mousecolours, labels = lab_list) + 
  xlab(bquote('Area '(µm^2))) +
  ylab("Adipocyte distribution") +
  labs(fill = NULL) +
  lapply(1:length(ul), function(i) {
    stat_function(fun = reg_gauss[[i]], args = list(ampl[[i]], mu[[i]], stddif[[i]]), aes(x = mids, y = counts),
                  size = 0.5, colour = mousecolours[i], xlim = c(-binsize/2,upper_limit+binsize/2))
  }
  ) + 
  scale_x_continuous(
    breaks = histos1$mids,
    labels = tick_labels
  ) +
  coord_cartesian(expand = FALSE)


max_y <- ggplot_build(histoplot)$layout$panel_scales_y[[1]]$range$range

mousewisedf <- data.frame()
for(i in unique(individual_mice$Mouse_name)){
  mousewisedf <- rbind(mousewisedf, c(i, as.character(individual_mice[individual_mice$Mouse_name==i,]$Folders[1]), mean(individual_mice[individual_mice$Mouse_name==i,]$Area), length(individual_mice[individual_mice$Mouse_name==i,]$Area)))
}
colnames(mousewisedf) <- c("Mouse_name", "Folders","Area","Count")
mousewisedf$Area <- as.numeric(mousewisedf$Area)
mousewisedf$Count <- as.numeric(mousewisedf$Count)

areatest <- TukeyHSD(aov(Area ~ Folders, data = mousewisedf), conf.level = 0.95)


theme_sideplot <- function() {
  font <- "Arial"
  theme_minimal() %+replace%
  theme(
    text = element_text(size = 8),
    panel.background = element_rect(fill = "transparent",colour = NA),
    axis.line = element_line(colour = "black"),
    axis.ticks.x = element_blank(),
    axis.text.x = element_blank(),,
    axis.ticks.y = element_line(colour = "black"),
    validate = TRUE,
    strip.background = element_rect(fill = "white"),
    legend.position = NULL,
    panel.grid = element_line(colour = NA),
    line = element_line(linewidth = 0.25),
  )
}

areaplot <- mousewisedf %>% 
  mutate(Folders = fct_relevel(Folders, levels(ul))) %>% 
  ggplot(aes(x = Folders, y = Area)) +
  stat_summary(fun = mean, geom = "col", color = "black", fill = mousecolours, size = 0.25, position = position_dodge2( padding = 0.5)) + 
  scale_fill_manual(values = mousecolours) +
  geom_point(position = position_jitter(width = 0.4), size = 0.25) +
  stat_summary(fun = mean, fun.min = function(x) mean(x) - sd(x), 
               fun.max = function(x) mean(x) + sd(x),
               geom = 'errorbar',  width = 0.25, size = 0.25) +
  ylab(bquote('area '(µm^2))) +
  labs(fill = NULL) +
  xlab(NULL) + 
  guides(fill="none") +
  theme_sideplot() 
  
countplot <- mousewisedf %>% 
  mutate(Folders = fct_relevel(Folders, levels(ul))) %>% 
  ggplot(aes(x = Folders, y = Count)) +
  stat_summary(fun = mean, geom = "bar", color = "black", fill = mousecolours, size = 0.25) + 
  geom_point(position = position_jitter(width = 0.3), size = 0.25) +
  stat_summary(fun = mean, fun.min = function(x) mean(x) - sd(x), 
               fun.max = function(x) mean(x) + sd(x),
               geom = 'errorbar',  width = 0.25, size = 0.25) +
  ylab("Nr of cells") +
  scale_fill_manual(values = mousecolours) + 
  theme_sideplot() + 
  labs(fill = NULL) +
  xlab(NULL)

areaandcount <- as_grob(arrangeGrob(areaplot, countplot, nrow = 1))
histoplot +
  annotation_custom(
    grob = areaandcount,
    xmin = upper_limit/3,
    xmax = upper_limit,
    ymin = max_y[2]/2,
    ymax = max_y[2]
  )

ggsave(paste(graph_name, ".svg", sep = ""), path = output_path, height = 6, width = 9, units = "cm")
#ggsave(paste(graph_name, ".png", sep = ""), path = output_path, height = 6, width = 9, units = "cm")
TukeyHSD(aov(Area ~ Folders, data = mousewisedf))
TukeyHSD(aov(Count ~ Folders, data = mousewisedf))
