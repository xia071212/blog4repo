library(ggplot2)
library(tidyr)
if (!exists('analysis')) source('R/02_clean.R')
colors <- c('United States'='#264D7E','Japan'='#C24C3B','United Kingdom'='#8661A6','Canada'='#14877D','Switzerland'='#B47B12')
panel$country <- factor(panel$country,levels=countries)
analysis$country <- factor(analysis$country,levels=countries)
style <- theme_minimal(base_size=12,base_family='sans') + theme(
 plot.title=element_text(face='bold',size=18,color='#203149'),
 plot.subtitle=element_text(size=11,color='#536071',margin=margin(b=15)),
 plot.caption=element_text(size=9,hjust=0,color='#536071'),
 panel.grid.minor=element_blank(),legend.position='bottom',
 strip.text=element_text(face='bold',size=12),plot.margin=margin(18,22,15,15))
# Fixed, explicit affine mapping: right-axis index = 10 * left-axis value + 80.
# No scale chosen to maximize apparent comovement; levels are context only.
p1 <- ggplot(panel,aes(date)) +
 geom_line(aes(y=yield,color='10Y yield (left)',linetype='10Y yield (left)'),linewidth=0.7)+
 geom_line(aes(y=(neer-80)/10,color='NEER (right)',linetype='NEER (right)'),linewidth=0.8)+
 facet_wrap(~country,ncol=2,axes='all',axis.labels='all')+
 scale_color_manual(values=c('10Y yield (left)'='#264D7E','NEER (right)'='#B47B12'),name=NULL)+
 scale_linetype_manual(values=c('10Y yield (left)'='solid','NEER (right)'='22'),name=NULL)+
 scale_y_continuous('10Y government bond yield (% per year)',limits=c(-2,6),breaks=seq(-2,6,2),
 sec.axis=sec_axis(~.*10+80,name='Broad NEER (2020 = 100)',breaks=seq(60,140,20)))+
 scale_x_date(date_breaks='2 years',date_labels='%Y',expand=expansion(mult=c(.01,.015)))+
 labs(title='Higher yields, different currency paths',
 subtitle='January 2017-April 2026 | Each panel pairs one country\'s yield and broad currency index',x=NULL,
 caption='Source: OECD Financial Market; BIS broad NEER. Identical axis ranges across countries.\nDual axes use different units: crossings and visual slopes do not measure correlation or valuation.')+style+
 theme(panel.spacing=grid::unit(1.5,'lines'))
scatter <- function(data,x,y,stat_col,title,subtitle,xlabel,ylabel,ncol) {
 ann <- stats |> filter(country %in% as.character(unique(data$country))) |>
 mutate(country=factor(country,levels=countries),label=sprintf('r = %.2f  |  n = %d',.data[[stat_col]],n))
 ggplot(data,aes(.data[[x]],.data[[y]],color=country))+
 geom_hline(yintercept=0,color='#CDD2D9',linewidth=.4)+geom_vline(xintercept=0,color='#CDD2D9',linewidth=.4)+
 geom_point(alpha=.55,size=1.7)+geom_smooth(method='lm',formula=y~x,se=FALSE,linewidth=.8)+
 geom_text(data=ann,aes(x=-Inf,y=Inf,label=label),inherit.aes=FALSE,hjust=-.1,vjust=1.5,size=3.4,color='#203149')+
 facet_wrap(~country,ncol=ncol)+scale_color_manual(values=colors,guide='none')+
 scale_y_continuous(expand=expansion(mult=c(.08,.18)))+
 labs(title=title,subtitle=subtitle,x=xlabel,y=ylabel,
 caption='Source: OECD and BIS; author calculations. January 2018-April 2026.\nEach dot is a month. Lines are descriptive OLS fits; overlapping 12-month windows are not independent.')+style
}
p2 <- scatter(analysis,'dy12','neer12','r_absolute_neer','Does a rise in domestic yields travel with appreciation?',
 'Absolute-yield intuition | A common scale makes country differences visible',
 '12-month change in domestic 10Y yield (percentage points)',
 '12-month NEER appreciation (%)',3)
p3 <- scatter(filter(analysis,country!='United States'),'ds12','fx12','r_relative_usd',
 'Relative yields align better in some countries',
 'Against the US dollar | The United Kingdom remains an exception',
 '12-month change in domestic minus US 10Y yield (percentage points)',
 '12-month local currency appreciation vs USD (%)',2)
dir.create('figures',showWarnings=FALSE)
for (i in 1:3) {
 p <- get(paste0('p',i)); h <- if(i==1) 10.2 else 7.2
 ggsave(sprintf('figures/figure%d.png',i),p,width=11.5,height=h,dpi=200,bg='white')
 ggsave(sprintf('figures/figure%d.pdf',i),p,width=11.5,height=h,device="pdf",bg='white')
}
