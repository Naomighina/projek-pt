# Server
# Server
server <- function(input, output, session) {
  
  # Paths to default CSV files
  default_kabupaten_path <- "C://Projek PT//kabupatendata.csv"
  default_provinsi_path <- "C://Projek PT//dataprovinsi.csv"
  
  # Reactive value to store CSV data
  csv_data <- reactiveVal(NULL)
  
  # Load default CSV data
  observe({
    if (file.exists(default_kabupaten_path) && file.exists(default_provinsi_path)) {
      df_kabupaten <- read.csv(default_kabupaten_path, stringsAsFactors = FALSE)
      df_provinsi <- read.csv(default_provinsi_path, stringsAsFactors = FALSE)
      
      # Convert Longitude and Latitude to numeric and handle non-numeric values
      df_kabupaten$Longitude <- as.numeric(df_kabupaten$Longitude)
      df_kabupaten$Latitude <- as.numeric(df_kabupaten$Latitude)
      df_provinsi$Longitude <- as.numeric(df_provinsi$Longitude)
      df_provinsi$Latitude <- as.numeric(df_provinsi$Latitude)
      
      # Remove rows with NA values in Longitude or Latitude
      df_kabupaten <- df_kabupaten %>%
        filter(!is.na(Longitude) & !is.na(Latitude))
      df_provinsi <- df_provinsi %>%
        filter(!is.na(Longitude) & !is.na(Latitude))
      
      # Store data in reactive value
      csv_data(list(kabupaten = df_kabupaten, provinsi = df_provinsi))
      
      # Update select inputs
      updateSelectInput(session, "provinsi_select", choices = unique(df_provinsi$Provinsi))
      updateSelectInput(session, "kabupaten_select", choices = unique(df_kabupaten$Kabupaten))
    } else {
      stop("File default tidak ditemukan.")
    }
  })
  
  # Observe selection of provinsi to update kabupaten choices
  observeEvent(input$provinsi_select, {
    req(csv_data())
    selected_provinsi <- input$provinsi_select
    
    df_kabupaten <- csv_data()$kabupaten
    
    # Filter kabupaten by selected provinsi
    filtered_kabupaten <- df_kabupaten %>%
      filter(Provinsi == selected_provinsi) %>%
      pull(Kabupaten)
    
    # Update kabupaten select input
    updateSelectInput(session, "kabupaten_select", choices = filtered_kabupaten)
  })
  
  # Initialize leaflet map
  output$map <- renderLeaflet({
    req(csv_data())
    
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap) %>%
      setView(lng = 113.9213, lat = -0.7893, zoom = 4.5)
  })
  
  # Observe map type selection and update markers and legend
  observe({
    req(input$map_type)
    df_combined <- csv_data()
    
    map_type <- input$map_type
    df <- switch(map_type,
                 "kabupaten_pemasaran" = df_combined$kabupaten,
                 "kabupaten_pengembangan" = df_combined$kabupaten,
                 "provinsi" = df_combined$provinsi
    )
    
    # Function to set colors based on cluster
    getClusterColor <- function(cluster) {
      sapply(cluster, function(c) {
        if (c == 0) {
          return('red')
        } else if (c == 1) {
          return('blue')
        } else if (c == 2) {
          return('yellow')
        } else if (c == 3) {
          return('green')
        } else if (c == 4) {
          return('purple')
        } else {
          return('gray') # Default color for unexpected values
        }
      })
    }
    
    # Generate icons with color based on cluster
    icons <- awesomeIcons(
      icon = 'ios-close',
      iconColor = ~getClusterColor(if(map_type %in% c("kabupaten_pemasaran", "kabupaten_pengembangan")) Cluster.kab else Cluster.prov),
      library = 'ion'
    )
    
    leafletProxy("map") %>%
      clearMarkers() %>%
      clearShapes() %>%
      clearControls() %>%  # Clear any existing controls (including legends)
      addAwesomeMarkers(
        data = df, lng = ~Longitude, lat = ~Latitude, icon = icons,
        popup = ~paste(
          "<b>", if(map_type %in% c("kabupaten_pemasaran", "kabupaten_pengembangan")) df$Kabupaten else df$Provinsi, "</b><br>",
          paste0(
            if(map_type == "kabupaten_pemasaran") {
              paste0("<b>Cluster:</b>", df$Cluster.kab, "<br>",
                     "<b>Classification:</b>", df$Classification.kab, "<br>",
                     "<b>APK SMA:</b> ", df$APK.SMA, "<br>",
                     "<b>Jumlah Penduduk:</b> ", df$Jumlah.Penduduk.Kab, "<br>",
                     "<b>PDRB:</b> ", df$PDRB.Rupiah.Kab, "<br>",
                     "<b>Rasio Minat:</b> ", df$Rasio.kab, "<br>",
                     "<b>Rasio Nyata:</b> ", df$Rasio.Nyata)
            } else if(map_type == "kabupaten_pengembangan") {
              paste0("<b>Cluster:</b>", df$Cluster.kab, "<br>",
                     "<b>Classification:</b>", df$Classification.kab, "<br>",
                     "<b>Jumlah Mahasiswa:</b> ", df$Jumlah.Mahasiswa, "<br>",
                     "<b>Jumlah Perguruan Tinggi:</b> ", df$Jumlah.Perguruan.Tinggi, "<br>",
                     "<b>Jumlah Mahasiswa PSDKU:</b> ", df$Jumlah.Mahasiswa.PSDKU, "<br>",
                     "<b>Peluang mahasiswa PSDKU2:</b> ", df$Peluang.mahasiswa.PSDKU)
            } else {
              paste0("<b>Cluster:</b>", df$Cluster.prov, "<br>",
                     "<b>Classification:</b>", df$Classification.prov, "<br>",
                     "<b>Jumlah Penduduk:</b> ", df$Jumlah.Penduduk.Prov, "<br>",
                     "<b>PDRB:</b> ", df$PDRB.Rupiah.Prov, "<br>",
                     "<b>APK SMA:</b> ", df$APKSMA.prov, "<br>",
                     "<b>Jumlah Umur 15-19:</b> ", df$JumlahUmur15.19.prov, "<br>",
                     "<b>Jumlah Murid SMASMK:</b> ", df$JumlahMuridSMASMK.prov, "<br>",
                     "<b>Jumlah PSDKU:</b> ", df$JumlahPSDKU.prov, "<br>",
                     "<b>Jumlah Mahasiswa PSDKU:</b> ", df$JumlahMahasiswaPSDKU.prov, "<br>",
                     "<b>Jumlah PJJ:</b> ", df$JumlahPJJ.prov, "<br>",
                     "<b>Jumlah Perguruan Tinggi :</b> ", df$JumlahPerguruanTinggi, "<br>",
                     "<b>Jumlah Mahasiswa Perguruan Tinggi :</b> ", df$JumlahMahasiswaPT.prov, "<br>",
                     "<b>Berapa orang yang mau kuliah:</b> ", df$Berapaorangyangmau.kuliah, "<br>",
                     "<b>Rasio Minat:</b> ", df$Rasio.prov, "<br>",
                     "<b>Sisa:</b> ", df$Sisa.prov, "<br>",
                     "<b>Rasio Nyata:</b> ", df$RasioNyata.prov)
            }
          )
        )
      ) %>%
      # Add legend based on map_type
      addLegend(
        position = "bottomleft", 
        colors = c("red", "blue", "yellow", "green", "purple"), 
        labels = if (map_type == "provinsi") {
          c("A : 2.801 - 3.926 (RM), 0.413 - 0.765 (RN)", "B : 0.596 - 1.708 (RM), 0.754 - 1.876 (RN)", "C : 4.503 - 5.817 (RM), 0.352 - 0.495 (RN)", "D : 0.514 - 0.551 (RM), 3.023 - 3.122 (RN)", "E: 1.841 - 2.722 (RM), 0.679 - 1.071 (RN)")
        } else {
          c("A : 0 - 20.21 (RM), 0 - 6.67 (RN)", "B : 500.78 - 509.1 (RM), 0 - 0 (RN)", "C : 235.12 - 357.44 (RM), 0 - 0 (RN)", "D : 21.68 - 66.42 (RM), 0.01 - 0.05 (RN)", "E : 81.17 - 165.17 (RM), 0.01 - 0.01 (RN)")
        },
        title = htmltools::HTML("<strong>Cluster</strong>"),
        opacity = 0.8
      )
  })
  
  # Update kabupaten select input based on selected provinsi
  observe({
    req(csv_data())
    df_kabupaten <- csv_data()$kabupaten
    
    selected_provinsi <- input$provinsi_select
    
    # Filter kabupaten based on selected provinsi
    if (!is.null(selected_provinsi)) {
      filtered_kabupaten <- df_kabupaten %>%
        filter(Provinsi == selected_provinsi)
      
      updateSelectInput(session, "kabupaten_select", choices = unique(filtered_kabupaten$Kabupaten))
    }
  })
  
  # Search and zoom to selected province
  observeEvent(input$search_provinsi_btn, {
    selected_provinsi <- input$provinsi_select
    df_provinsi <- csv_data()$provinsi
    
    provinsi_row <- df_provinsi %>% filter(Provinsi == selected_provinsi)
    
    if (nrow(provinsi_row) > 0) {
      leafletProxy("map") %>%
        setView(lng = provinsi_row$Longitude, lat = provinsi_row$Latitude, zoom = 11)
    }
  })
  
  # Search and zoom to selected kabupaten
  observeEvent(input$search_kabupaten_btn, {
    selected_kabupaten <- input$kabupaten_select
    df_kabupaten <- csv_data()$kabupaten
    
    kabupaten_row <- df_kabupaten %>% filter(Kabupaten == selected_kabupaten)
    
    if (nrow(kabupaten_row) > 0) {
      leafletProxy("map") %>%
        setView(lng = kabupaten_row$Longitude, lat = kabupaten_row$Latitude, zoom = 13)
    }
  })
  
}


shinyApp(ui = ui, server = server)