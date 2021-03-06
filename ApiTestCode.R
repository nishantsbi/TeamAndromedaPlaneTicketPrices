####################
####### Prep #######
####################

library("dplyr")
library("jsonlite")
library("knitr")
library("httr")
library("ggplot2")
library("XML")
library("rgdal")
library("data.table")
library("raster")
library("grid")
library("sp")
#Variables:
country = "US"
currency = "USD"
locale = "en-us"
originplace="BOS"
destinationplace="YAM"
outbounddate="2017-03-20"
#inbounddate="2017-12"
apikey="te892026803091243844897141219716"

####################
####### JSON #######
####################
require(jsonlite)

countriesList <- GET("http://partners.api.skyscanner.net/apiservices/geo/v1.0?apiKey=te892026803091243844897141219716")
countriesList <- fromJSON(content(countriesList, "text"))

countriesListdf <- flatten(countriesList)

routes.url <- paste0("http://partners.api.skyscanner.net/apiservices/browsequotes/v1.0/",country,"/",currency,"/",locale,"/",originplace,"/",destinationplace,"/", outbounddate,"?apiKey=", apikey)

response <- GET(routes.url)
query <- fromJSON(content(response, "text"))

places <- flatten(query$Places)
#routes <- flatten(query$Routes)
quotes <- flatten(query$Quotes) #%>% dplyr::select(2,7,8)

carriers <- flatten(query$Carriers)
#currencies <-flatten(query$Currencies)

places.countries.only <- filter(places, Type == "Country") %>% dplyr::select(2,4)
places.stations.only <- filter(places, Type == "Station") #dplyr::select(1,6,8) %>% 
from <- places.stations.only %>% filter(CountryName = )

   places.min.price <- summarise(group_by(places.stations.only, PlaceId),m = min(MinPrice))
places.stations.only <- places.stations.only %>%  dplyr::select(1:3,5,6,8) %>% 
   unique() %>% left_join(places.min.price) %>% na.omit()

places.stations.only <- arrange(places.stations.only, m) %>% filter(CountryName != "United States")  %>% 
   top_n(-5) # %>% 

places.stations.only <- left_join(places.stations.only ,carriers, by = c("OutboundLeg.CarrierIds" = "CarrierId"))


world <- map_data('world') %>% filter(region!='Antarctica')

world <- mutate(world, code = iso.alpha(world$region, n=2)) %>%
  left_join(places.countries.only, by = c("code" = "SkyscannerCode")) %>% 
  unique()

worldForHeatmap <- inner_join(world, places.stations.only, by = c("Name" = "CountryName")) %>% dplyr::select(long,lat,m,group)%>%  na.omit()
colnames(worldForHeatmap) <- c("x","y","m","group")

########################
#########PLOT###########
########################
breaks = c(0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 10000)
ggplot(data = world) + 
   geom_polygon(aes(long,lat,group=group),fill="white",colour="black",size=0.1) +
   coord_equal() + 
   scale_x_continuous(expand=c(0,0)) + 
   scale_y_continuous(expand=c(0,0)) +
   labs(x='Longitude', y='Latitude') +
   theme_bw()+
   geom_polygon(data = worldForHeatmap, aes(x = x, y = y, group=group, fill = cut(m, breaks))) +
   scale_fill_brewer(palette = "RdYlGn", direction = -1) +
   coord_quickmap() + 
   labs(x='Longitude', y='Latitude', title = "Prices Based on Destination")