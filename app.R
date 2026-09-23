library(shiny)
library(shinydashboard)
library(mrgsolve)
library(dplyr)
library(tidyr)
library(ggplot2)
library(DT)

# Load PK model
amikacin <- mread("amikacin", project = ".")

# ================= UI =================
ui <- dashboardPage(
  
  dashboardHeader(title = "Amikacin PK/PD Dashboard"),
  
  dashboardSidebar(
    
    # Patient covariates
    numericInput("wt", "Weight (kg)", 60),
    numericInput("age", "Age (years)", 40),
    selectInput("sex", "Sex", choices = c("Male" = 1, "Female" = 0)),
    numericInput("scr", "Serum Creatinine", 0.5),
    
    # Run simulation
    actionButton("run", "Run Simulation", class = "btn-success")
  ),
  
  dashboardBody(
    
    fluidRow(
      box(title = "Dose Optimization Table", width = 12, DTOutput("pk_table"))
    ),
    
    fluidRow(
      box(title = "Concentration-Time Profiles", width = 12, plotOutput("pk_plot", height = 500))
    )
  )
)

# ================= SERVER =================
server <- function(input, output, session) {
  
  # Dose regimens to evaluate
  doses <- c(250, 500, 750, 1000)
  intervals <- c(12, 24, 48)
  
  sim_data <- eventReactive(input$run, {
    
    # Function to simulate one regimen
    run_one <- function(dose, ii) {
      
      sim_df <- amikacin %>%
        param(
          WT  = as.numeric(input$wt),
          AGE = as.numeric(input$age),
          SEX = as.numeric(as.character(input$sex)),
          SCr = as.numeric(input$scr)
        ) %>%
        ev(
          amt = dose,
          ii = ii
        ) %>%
        mrgsim(
          end = ii,
          delta = 0.25,
          obsonly = TRUE,
          
          # Remove variability for deterministic simulation
          omega = matrix(0, nrow = 4, ncol = 4)
        ) %>%
        as.data.frame()
      
      # PK metrics
      cmax <- max(sim_df$CP, na.rm = TRUE)
      cmin <- tail(sim_df$CP, 1)
      
      # Target attainment criteria
      status <- ifelse(cmax > 25 & cmin < 2.5, "Ideal", "Not Ideal")
      
      list(
        df = sim_df,
        summary = data.frame(
          Dose = paste0(dose, " mg"),
          Frequency = paste0("q", ii, "h"),
          Peak = round(cmax, 2),
          Trough = round(cmin, 2),
          Status = status
        )
      )
    }
    
    all_sims <- list()
    summary_tables <- list()
    counter <- 1
    
    # Run all dose-interval combinations
    for (d in doses) {
      for (ii in intervals) {
        
        res <- run_one(d, ii)
        name <- paste0(d, "mg_q", ii, "h")
        
        all_sims[[name]] <- res$df
        all_sims[[name]]$Regimen <- name
        all_sims[[name]]$Dose <- paste0(d, " mg")
        
        summary_tables[[counter]] <- res$summary
        counter <- counter + 1
      }
    }
    
    list(
      sim = all_sims,
      summary = bind_rows(summary_tables)
    )
  })
  
  # ================= TABLE =================
  output$pk_table <- renderDT({
    
    datatable(
      sim_data()$summary,
      options = list(
        paging = FALSE,
        searching = FALSE,
        info = FALSE,
        dom = "t"
      )
    ) %>%
      
      # Highlight ideal regimens
      formatStyle(
        "Status",
        target = "row",
        backgroundColor = styleEqual(
          c("Ideal", "Not Ideal"),
          c("#d4edda", "white")
        ),
        fontWeight = styleEqual(
          c("Ideal", "Not Ideal"),
          c("bold", "normal")
        )
      )
  })
  
  # ================= PLOT =================
  output$pk_plot <- renderPlot({
    
    plot_df <- bind_rows(sim_data()$sim)
    
    ggplot(plot_df, aes(x = time, y = CP, color = Dose)) +
      geom_line(size = 1) +
      
      # PK target lines
      geom_hline(yintercept = 25, linetype = "dashed", color = "darkgreen") +
      geom_hline(yintercept = 2.5, linetype = "dashed", color = "red") +
      scale_x_continuous(breaks = c(12, 24, 36, 48, 60)) +
      
      labs(
        x = "Time (h)",
        y = "Concentration"
      ) +
      
      theme_minimal()
  })
}

# ================= RUN APP =================
shinyApp(ui, server)