[PROB]
- Author: Ivan Nicholas Nkuhairwe
- Description: Amikacin


[PARAM] @annotated
// PK parameter values
TVCL      : 3.9   : Clearance (L/h)
TVVC      : 13.9   : Volume of central compartment (L)
TVKA      : 1.78  : Absorption rate constant (1/h)
TVV2      : 15.9   : Volume of peripheral compartment 1 (L)
TVQ       : 1.17  : Intercompartmental clearance (L/h)
CLNR	  : 0		: Non-renal clearance
TVF : 1	: Fixed bioavailability
FU : 0.9	: Free fraction

// Patient characteristics/ typical values
WT : 55	: Weight
HT : 1.6 : Height
SEX : 1	: Male=1, Female= 0
AGE : 25	: Age in years
SCr : 0.8	: Serum creatinine
// Typical values 
TVWT : 55 : median weight(kg)
TVFAT : 17	: median fat (kg)
TVFFM : 38	: median FFM (kg)

[CMT] @annotated
GUT : Absorption
CENT : Central
PERI : Peripheral


[OMEGA] @annotated
// Inter-individual variability (BSV)
ETA_CL  : 0.059049 : BSV CL
ETA_V  : 0.056644 : BSV V
ETA_KA : 0.242064	: BOV KA
ETA_BIO : 0.0289	: BOVBIO

[SIGMA] @annotated
// Residual variability
PROP : 0.0445        : Proportional error (fixed)
ADD : 0.5			: 20% Additive error inflation

[MAIN]
// Covariates and transformations

double WHSMAX; //Declaring
double WHS50;  //Declaring
//Adding Allometric Scaling
if (SEX == 0){
    WHSMAX=37.99;
	WHS50=35.98;
}else{
    WHSMAX=42.92;
	WHS50=30.93;
}
double HTM2 = pow(HT,2);
double FFM = (WHSMAX * HTM2 * WT) / (WHS50 * HTM2 + WT);
double FAT = WT - FFM;

// Allometric scaling

double ALLMCL_WT = pow(WT / TVWT, 0.75);
double ALLMV_WT = (WT / TVWT);
double ALLMCL_FFM = pow(FFM / TVFFM, 0.75);
double ALLMV_FFM = (FFM / TVFFM);
// CRCL effect on CL

double CRCL;
/*if (SEX == 0) {
  // Female
  CRCL = (((140 - AGE) * WT) / (CRT * 72)) * 0.85;
} else {
  // Male or unspecified sex
  CRCL = ((140 - AGE) * WT) / (CRT * 72);
}*/

// Male or unspecified sex(When using FFM, no need to re adjust for sex)

  CRCL = ((140 - AGE) * WT) / (SCr * 72);



double CRCL_STD = CRCL * 55 / WT; // Standardize CRCL

//double eCR = (1 + CRT_CL * (CRCL_STD - 108)); // CRCL effect

double RF = CRCL_STD / 135; // RENAL FUNCTION

// Typical values
double CL = ((TVCL * RF) + CLNR) * ALLMCL_FFM * exp(ETA_CL);
double V = TVVC * ALLMV_FFM * exp(ETA_V);
double KA = TVKA * exp(ETA_KA);
double V2 = TVV2 * ALLMV_FFM;
double Q = TVQ * ALLMCL_FFM;
double F = TVF * exp(ETA_BIO) ;


// Transit compartment model reparameterization

double K = CL/ V;
double K23 = Q / V;
double K32 = Q / V2;

[ODE]
// Differential equations for transit compartments
dxdt_GUT = -KA * GUT;
dxdt_CENT = KA * GUT - K * CENT - K23 * CENT + K32 * PERI;
dxdt_PERI = K23 * CENT - K32 * PERI;

[TABLE]
capture CP = CENT / V;
capture CU = ((CENT / V)*FU);
//capture CLcr = CRCL

/* [CAPTURE]
FFM;
RF;
CRCL_STD;
ETA_CL;
ETA_V;
ETA_KA;
ETA_BIO;
CL;
V;
ALLMCL_FFM; */