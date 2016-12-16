******************************************
* Building the File for PS 239T Final Project
* 
*******************************************
clear
set more off

*******
** Step 1: Pull in a list of all school districts with CDS and NCES IDs

use "/Users/lindsaymaple/Dropbox/California/CA Facilities Funding Analysis 2014-15/Combined analysis_LM/Stata File/CountSchoolsOutput.dta"

rename (NCESDist CDSDist CDSCounty District County DOC Active) (nces_id cds_id county_code district_name county_name district_type school_count)

gen district_type2 = 3
replace district_type2 = 0 if district_type == "54"
replace district_type2 = 1 if district_type == "56"
replace district_type2 = 2 if district_type == "52"


save "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/Projection_Data", replace

*******
** Step 2: Add in 2015 Enrollment Data from 2015

clear 
import delimited "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/2015enrollment.txt"

* combine grade level values into Elementary, Middle and High School. Drop grade level variables 
gen enroll_es =  kdgn + gr_1 + gr_2 + gr_3 + gr_4 + gr_5 +  gr_6 + ungr_elm
gen enroll_ms = gr_7 + gr_8
gen enroll_hs = gr_9 + gr_10 + gr_11 + gr_12 + ungr_sec

drop  kdgn gr_1 gr_2 gr_3 gr_4 gr_5 gr_6 gr_7 gr_8 ungr_elm gr_9 gr_10 gr_11 gr_12 ungr_sec

* generate race variables 
format %014.0f cds_code
tostring cds_code, generate(cds_string) force format (%014.0f)
gen cds_id = substr( cds_string, 3, 5)
sort cds_id

collapse (firstnm) district (sum) enr_total adult enroll_es enroll_ms enroll_hs, by (cds_id ethnic)

gen race_hisp = enr_total if ethnic == 5
gen race_afam = enr_total if ethnic == 6
gen race_white = enr_total if ethnic == 7

* collapse into one row per district
collapse (firstnm) district (sum) enr_total adult enroll_es enroll_ms enroll_hs race_hisp race_afam race_white, by (cds_id)

* merge with district ID list
save "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/2015_Enrollment", replace

clear

use "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/Projection_Data"
merge m:1  cds_id using "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/2015_Enrollment"
* 1029 districts matched, 157 not in enrollment (Elementaries, ROPs, SBEs)

drop _merge district

save "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/Projection_Data", replace


** Step 3:  Add in county pop growth projections
clear

import excel "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/pop_growth.xls", sheet("2010 to 2020 school") firstrow

rename (StateCounty SchoolAge517years C Change) (county_name youth_pop2010 youth_pop2020 county_growth)
drop if county_name == "California"

save "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/County_Growth", replace

* merge to main file
clear
use "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/Projection_Data"
merge m:1  county_name using "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/County_Growth"
* all matched 

drop youth_pop2010 youth_pop2020 _merge

save "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/Projection_Data", replace

** Step 4: Add Assessed Value data
clear

import excel "/Users/lindsaymaple/Dropbox/California/CA Facilities Funding Analysis 2014-15/Combined analysis_LM/Stata File/AV and SFP from CDE.xlsx", sheet("Sheet1") firstrow case(lower)

keep cdscode district valuation2014 totalnewconstruction totalmodernization totalfinancialhardshipncm

rename (valuation2014 totalnewconstruction totalmodernization totalfinancialhardshipncm) (av sfp_nc sfp_mod sfp_fh)

replace sfp_nc = 0 if sfp_nc == . & av != .
replace sfp_mod = 0 if sfp_mod == . & av != .
replace sfp_fh = 0 if sfp_fh == . & av != .

gen sfp_total = sfp_nc + sfp_mod + sfp_fh
gen got_sfp = sfp_total > 0

gen cds_id = substr( cdscode, 3, 5)
sort cds_id

save "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/AV_2014", replace

* merge with main file
clear
use "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/Projection_Data"
merge m:1  cds_id using "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/AV_2014"
* 950 districts had data, 236 do not (including all the county offices of education

replace got_sfp = 0 if _merge == 1

drop _merge cdscode district

save "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/Projection_Data", replace


** Step 5: Add in NCES data from panel
clear
use "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/finance_panel.dta"
* this is already inflation adjusted to $2014

keep leaid name year v33 opsp_inf ltd_inf ps_localcap_inf ps_mo_inf

gen debt_2013 = ltd_inf if year == 2013
replace debt_2013 = 0 if debt_2013 < 0

gen opsp_2013 = opsp_inf if year == 2013
replace opsp_2013 = 0 if opsp_2013 < 0

gen localcap_2013 = ps_localcap_inf if year == 2013
gen localcap_for_max = ps_localcap_inf
gen localcap_for_75 = ps_localcap_inf

gen mo_2013 = ps_mo_inf if year == 2013

collapse (first) name (sum) debt_2013 opsp_2013 localcap_2013 mo_2013 (max) localcap_for_max (p75) localcap_for_75 (mean) ps_localcap_inf, by (leaid)

rename ps_localcap_inf localcap_avg

gen nces_id = "0" + leaid

save "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/nces_projection", replace

* merge with main file
clear
use "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/Projection_Data"
merge m:1  nces_id using "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/nces_projection"
* 1,087 merged, 99 unmatched from master, 35 unmatched from NCES
drop if _merge == 2

drop leaid name _merge

save "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/Projection_Data", replace

** Step 6: Add Bond Data
clear
use "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/bond_full_panel.dta"

gen bond_past2 = electionyear == 2014 | electionyear == 2013 & passed == 1
gen size_past2 = bond_past2 * bondsize

collapse (first) dname (sum) elections passed bondsize bond_past2 size_past2 (mean) yes_pct, by (dcode)

rename dcode cds_id

save "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/bonds_projection", replace

* merge with main file
clear
use "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/Projection_Data"
merge m:1  cds_id using "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/bonds_projection"
* 741 matched, 11 unmatched from the Bond file, 445 had no bond data
drop if _merge == 2

replace elections = 0 if _merge == 1
replace passed = 0 if _merge == 1
replace bond_past2 = 0 if _merge == 1
replace bondsize = 0 if _merge ==1
replace size_past2 = 0 if _merge == 1

drop _merge dname 

save "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/Projection_Data", replace


** STEP 7: Add LCFF data including current spending and unduplicated pupil counts
clear
import excel "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/lcffsnapshot15.xls", sheet("SD & Charter Snapshot File") cellrange(A9:AH2174) firstrow case(lower)

keep if charternumber == ""

keep districtcode localeducationalagency totalfundedada unduplicatedpupilpercentage basegrantfunding supplementalgrantfunding concentrationgrantfunding localrevenue educationprotectionaccountep lcffstateaidbeforemsa additionalsaformsa totalfunding

rename (districtcode localeducationalagency totalfundedada unduplicatedpupilpercentage basegrantfunding supplementalgrantfunding concentrationgrantfunding localrevenue educationprotectionaccountep lcffstateaidbeforemsa additionalsaformsa totalfunding) (cds_id lea_name total_ada udp_pct base supplemental concentration local_op epa_state lcff_state MSA_state total_opsp)

destring total_ada udp_pct base supplemental concentration local_op epa_state lcff_state MSA_state total_opsp, replace force

drop if cds_id == ""

* adjust for inflation

gen cpi = 236.736/237.017

replace base = base * cpi
replace supplemental = supplemental * cpi
replace concentration = concentration * cpi
replace local_op = local_op * cpi
replace epa_state = epa_state * cpi
replace lcff_state = lcff_state * cpi
replace MSA_state = MSA_state * cpi
replace total_opsp = total_opsp * cpi

gen state_op = epa_state + lcff_state + MSA_state


save "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/lcff", replace

clear
use "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/Projection_Data"
merge m:1  cds_id using "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/lcff"
*946 (all from LCFF data) matched 240 not matched.

drop lea_name epa_state lcff_state MSA_state _merge

save "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/Projection_Data", replace


**STEP 8: Add in Locale Codes
clear

use "/Users/lindsaymaple/Dropbox/California/CA Facilities Funding Analysis 2014-15/Combined analysis_LM/Stata File/LocaleOutput.dta"

gen urban = ulocale == "11" | ulocale == "12" | ulocale == "13"
gen suburban = ulocale == "21" | ulocale == "22" | ulocale == "23"
gen rural = ulocale == "41" | ulocale == "42" | ulocale == "43"

rename NCESDist nces_id

save "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/locale", replace

clear
use "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/Projection_Data"
merge m:1  nces_id using "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/locale"
* 7 unmatched from locale file, including a number that should be dropped anyway, 59 in main file with no locale match

drop if _merge == 2

drop leaid name05 _merge

save "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/Projection_Data", replace


** generate per puil AV and AV quintiles
gen avstudent = av / enr_total

sort avstudent
xtile av_quint = avstudent, nq (5)

** generate pass rate for bond elections
gen pass_rate = passed / elections

** drop the 88 LEAs with no schools (7 CEAs and 81 districts with no enrollment data and no LCFF data -- may be that these have closed since some have historic NCES data, some even in 2013, but fewer)
drop if school_count == 0

** drop the 76 other LEAs (almost all ROPs) where there is no enrollment data. There is also no NCES or LCFF data for all of these districts.
drop if enr_tot == .

** drop the SBEs, state special schools, CEA and SBC
drop if district_type == "02"
drop if district_type == "03"
drop if district_type == "31"
drop if district_type == "34"

** create indicator for COEs
gen is_coe = district_type == "00"

** we are left with 56 COEs, 527 ESDs, 343 USDs, 77 HSDs or 1,003 school districts in total


save "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Data/Projection_Data", replace

sort county_n district_n

export excel using "/Users/lindsaymaple/Documents/GSPP/Facilities APA/Model/projection_district_data.xlsx", firstrow(variables) replace



** CAP PREDICTION REGRESSION
gen bondsize_ps = bondsize / enr_tot
gen sfp_ps = sfp_total / enr_tot
gen fh_ps = sfp_fh / enr_tot
gen debt_ps = debt_2013 / enr_tot
gen lcff_op_ps = total_opsp / enr_tot

gen is_hsd = district_type == "56"


reg localcap_for_75 avstudent pass_rate bondsize_ps bond_past2 is_hsd is_coe sfp_ps fh_ps



