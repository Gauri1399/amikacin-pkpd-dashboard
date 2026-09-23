# Amikacin PK/PD Dashboard

An interactive R Shiny dashboard for simulating amikacin pharmacokinetics and evaluating different dosing regimens using an `mrgsolve` PK model.

## Features

- Patient-specific inputs for weight, age, sex, and serum creatinine
- Simulates amikacin doses of 250, 500, 750, and 1000 mg
- Compares q12h, q24h, and q48h dosing regimens
- Calculates simulated peak and trough concentrations
- Evaluates regimens against predefined PK/PD targets
- Visualizes concentration-time profiles
- Interactive dose optimization table

## PK/PD Targets

The dashboard evaluates dosing regimens using:

- Peak concentration > 25
- Trough concentration < 2.5

Regimens meeting both criteria are labeled "Ideal."

## Technologies

- R
- Shiny
- shinydashboard
- mrgsolve
- dplyr
- tidyr
- ggplot2
- DT
- Conda

## Project Structure

```text
amikacinapp/
├── app.R
├── amikacin.cpp (mrgsolve PK model input)
├── environment.yml
└── README.md
```

## Run Locally

Create the Conda environment:

```bash
conda env create -f environment.yml
```

Activate the environment:

```bash
conda activate amikacin-shiny
```

Run the application:

```r
shiny::runApp()
```

## Live Application

[Launch the Amikacin PK/PD Dashboard](https://agrawal-gauri.shinyapps.io/amikacinapp/)

````
