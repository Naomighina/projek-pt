library(shiny)
library(leaflet)
library(dplyr)
library(shinyWidgets)
library(DT)
library(RColorBrewer)
library(shinyjs)

# CSS Styling
custom_css <- "
  body { font-family: 'Times New Roman', serif; background: linear-gradient(to bottom right, #4f84ab, #49a09d); }
  .leaflet-container { background: #f9f9f9; }
  .sidebar-panel { background-color: #e0e0e0; }
  .main-panel { background-color: #ffffff; border-radius: 15px; box-shadow: 0 0 10px rgba(0, 0, 0, 0.1); padding: 20px; }
  .title-panel { color: #ffffff; font-size: 28px; font-weight: bold; text-align: center; margin: 20px 0; }
  .info-box { font-size: 16px; color: #333; }
  .details-table { background-color: #f0f0f0; border: 1px solid #ccc; border-radius: 5px; padding: 10px; }
  .leaflet-popup-content-wrapper { font-size: 14px; }
  .leaflet-control-layers { background: rgba(255, 255, 255, 0.8); }
  .control-label { font-size: 16px; font-weight: bold; }
  .control-group { margin-bottom: 15px; }
  .btn { background-color: #5f2c82; color: #ffffff; border-radius: 20px; padding: 5px 10px; font-size: 12px; }
  .btn:hover { background-color: #49a09d; }
  .panel-heading { background-color: #5f2c82 !important; color: #ffffff !important; border-radius: 5px 5px 0 0; }
  .panel-body { background-color: #ffffff; border-radius: 0 0 5px 5px; }
  .map-controls { 
    position: absolute; 
    top: 45%; 
    right: 45px; 
    background: rgba(255, 255, 255, 0.8); 
    padding: 5px; 
    border-radius: 5px; 
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.2); 
    transform: translateY(-50%); 
    width: 240px; 
    height: auto; 
  }
  .map-type-controls { 
    display: flex; 
    flex-direction: column; 
    align-items: flex-end; 
  }
  .search-controls { 
    margin-top: 10px; 
  }
  .selectInput, .actionButton {
    width: 150%; 
    font-size: 12px; 
  }
  .leaflet-control .legend-title {
        font-family: 'Times New Roman', Times New Roman;
        font-size: 14px;
        font-weight: bold;
      }
      .leaflet-control .legend-labels {
        font-family: 'Times New Roman', Times New Roman;
        font-size: 12px;
      }
      .leaflet-control {
        background-color: rgba(255, 255, 255, 0.5) !important; /* White background with 80% opacity */
      }
"

# UI
# UI
ui <- fluidPage(
  tags$head(
    tags$style(HTML(custom_css)),
    tags$script(src = "https://polyfill.io/v3/polyfill.min.js?features=es6"),
    tags$script(src = "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js")
  ),
  div(class = "title-panel", "Peta Interaktif Indonesia"),
  withMathJax(),
  div(class = "main-panel",
      leafletOutput("map", height = "535px"),
      div(class = "map-controls",
          div(class = "map-type-controls",
              radioButtons("map_type", "Pilih Tipe Peta:",
                           choices = list(
                             "Kabupaten (Pemasaran)" = "kabupaten_pemasaran",
                             "Kabupaten (Pengembangan)" = "kabupaten_pengembangan",
                             "Provinsi" = "provinsi"
                           ),
                           selected = "kabupaten_pemasaran")
          ),
          div(class = "search-controls",
              selectInput("provinsi_select", "Pilih Provinsi:", choices = NULL, selected = NULL),
              actionButton("search_provinsi_btn", "Tampilkan Provinsi", class = "btn"),
              selectInput("kabupaten_select", "Pilih Kabupaten:", choices = NULL, selected = NULL),
              actionButton("search_kabupaten_btn", "Tampilkan Kabupaten", class = "btn")
          )
      ),
      div(class = "mathjax-info",
          htmltools::HTML("
      <div><strong>Keterangan:</strong></div>
      <div>1. <strong>Rasio Minat (RM):</strong> \\( \\frac{(\\text{APK} \\times \\text{jumlah murid SMA SMK})}{100} \\div \\text{Jumlah mahasiswa} \\)</div>
      <div>2. <strong>Rasio Nyata (RN):</strong> \\( \\frac{\\text{Jumlah mahasiswa Total di Perguruan Tinggi}}{\\text{Jumlah murid SMA SMK}} \\)</div>
    ")
      )
      
  )
)
