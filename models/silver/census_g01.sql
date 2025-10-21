{{ config(materialized='table') }}

select
trim("LGA_CODE_2016")::text as lga_code,

nullif(trim("Tot_P_M"), '')::int as tot_p_m,
nullif(trim("Tot_P_F"), '')::int as tot_p_f,
nullif(trim("Tot_P_P"), '')::int as tot_p_p,

nullif(trim("Age_0_4_yr_M"), '')::int  as age_0_4_yr_m,
nullif(trim("Age_0_4_yr_F"), '')::int  as age_0_4_yr_f,
nullif(trim("Age_0_4_yr_P"), '')::int  as age_0_4_yr_p,

nullif(trim("Age_5_14_yr_M"), '')::int as age_5_14_yr_m,
nullif(trim("Age_5_14_yr_F"), '')::int as age_5_14_yr_f,
nullif(trim("Age_5_14_yr_P"), '')::int as age_5_14_yr_p,

nullif(trim("Age_15_19_yr_M"), '')::int as age_15_19_yr_m,
nullif(trim("Age_15_19_yr_F"), '')::int as age_15_19_yr_f,
nullif(trim("Age_15_19_yr_P"), '')::int as age_15_19_yr_p,

nullif(trim("Age_20_24_yr_M"), '')::int as age_20_24_yr_m,
nullif(trim("Age_20_24_yr_F"), '')::int as age_20_24_yr_f,
nullif(trim("Age_20_24_yr_P"), '')::int as age_20_24_yr_p,

nullif(trim("Age_25_34_yr_M"), '')::int as age_25_34_yr_m,
nullif(trim("Age_25_34_yr_F"), '')::int as age_25_34_yr_f,
nullif(trim("Age_25_34_yr_P"), '')::int as age_25_34_yr_p,

nullif(trim("Age_35_44_yr_M"), '')::int as age_35_44_yr_m,
nullif(trim("Age_35_44_yr_F"), '')::int as age_35_44_yr_f,
nullif(trim("Age_35_44_yr_P"), '')::int as age_35_44_yr_p,

nullif(trim("Age_45_54_yr_M"), '')::int as age_45_54_yr_m,
nullif(trim("Age_45_54_yr_F"), '')::int as age_45_54_yr_f,
nullif(trim("Age_45_54_yr_P"), '')::int as age_45_54_yr_p,

nullif(trim("Age_55_64_yr_M"), '')::int as age_55_64_yr_m,
nullif(trim("Age_55_64_yr_F"), '')::int as age_55_64_yr_f,
nullif(trim("Age_55_64_yr_P"), '')::int as age_55_64_yr_p,

nullif(trim("Age_65_74_yr_M"), '')::int as age_65_74_yr_m,
nullif(trim("Age_65_74_yr_F"), '')::int as age_65_74_yr_f,
nullif(trim("Age_65_74_yr_P"), '')::int as age_65_74_yr_p,

nullif(trim("Age_75_84_yr_M"), '')::int as age_75_84_yr_m,
nullif(trim("Age_75_84_yr_F"), '')::int as age_75_84_yr_f,
nullif(trim("Age_75_84_yr_P"), '')::int as age_75_84_yr_p,

nullif(trim("Age_85ov_M"), '')::int as age_85ov_m,
nullif(trim("Age_85ov_F"), '')::int as age_85ov_f,
nullif(trim("Age_85ov_P"), '')::int as age_85ov_p,

nullif(trim("Counted_Census_Night_home_M"), '')::int as counted_census_night_home_m,
nullif(trim("Counted_Census_Night_home_F"), '')::int as counted_census_night_home_f,
nullif(trim("Counted_Census_Night_home_P"), '')::int as counted_census_night_home_p,

nullif(trim("Count_Census_Nt_Ewhere_Aust_M"), '')::int as count_census_nt_ewhere_aust_m,
nullif(trim("Count_Census_Nt_Ewhere_Aust_F"), '')::int as count_census_nt_ewhere_aust_f,
nullif(trim("Count_Census_Nt_Ewhere_Aust_P"), '')::int as count_census_nt_ewhere_aust_p,

nullif(trim("Indigenous_psns_Aboriginal_M"), '')::int as indigenous_psns_aboriginal_m,
nullif(trim("Indigenous_psns_Aboriginal_F"), '')::int as indigenous_psns_aboriginal_f,
nullif(trim("Indigenous_psns_Aboriginal_P"), '')::int as indigenous_psns_aboriginal_p,

nullif(trim("Indig_psns_Torres_Strait_Is_M"), '')::int as indig_psns_torres_strait_is_m,
nullif(trim("Indig_psns_Torres_Strait_Is_F"), '')::int as indig_psns_torres_strait_is_f,
nullif(trim("Indig_psns_Torres_Strait_Is_P"), '')::int as indig_psns_torres_strait_is_p,

nullif(trim("Indig_Bth_Abor_Torres_St_Is_M"), '')::int as indig_bth_abor_torres_st_is_m,
nullif(trim("Indig_Bth_Abor_Torres_St_Is_F"), '')::int as indig_bth_abor_torres_st_is_f,
nullif(trim("Indig_Bth_Abor_Torres_St_Is_P"), '')::int as indig_bth_abor_torres_st_is_p,

nullif(trim("Indigenous_P_Tot_M"), '')::int as indigenous_p_tot_m,
nullif(trim("Indigenous_P_Tot_F"), '')::int as indigenous_p_tot_f,
nullif(trim("Indigenous_P_Tot_P"), '')::int as indigenous_p_tot_p,

nullif(trim("Birthplace_Australia_M"), '')::int as birthplace_australia_m,
nullif(trim("Birthplace_Australia_F"), '')::int as birthplace_australia_f,
nullif(trim("Birthplace_Australia_P"), '')::int as birthplace_australia_p,

nullif(trim("Birthplace_Elsewhere_M"), '')::int as birthplace_elsewhere_m,
nullif(trim("Birthplace_Elsewhere_F"), '')::int as birthplace_elsewhere_f,
nullif(trim("Birthplace_Elsewhere_P"), '')::int as birthplace_elsewhere_p,

nullif(trim("Lang_spoken_home_Eng_only_M"), '')::int as lang_spoken_home_eng_only_m,
nullif(trim("Lang_spoken_home_Eng_only_F"), '')::int as lang_spoken_home_eng_only_f,
nullif(trim("Lang_spoken_home_Eng_only_P"), '')::int as lang_spoken_home_eng_only_p,

nullif(trim("Lang_spoken_home_Oth_Lang_M"), '')::int as lang_spoken_home_oth_lang_m,
nullif(trim("Lang_spoken_home_Oth_Lang_F"), '')::int as lang_spoken_home_oth_lang_f,
nullif(trim("Lang_spoken_home_Oth_Lang_P"), '')::int as lang_spoken_home_oth_lang_p,

nullif(trim("Australian_citizen_M"), '')::int as australian_citizen_m,
nullif(trim("Australian_citizen_F"), '')::int as australian_citizen_f,
nullif(trim("Australian_citizen_P"), '')::int as australian_citizen_p,

nullif(trim("Age_psns_att_educ_inst_0_4_M"), '')::int as age_psns_att_educ_inst_0_4_m,
nullif(trim("Age_psns_att_educ_inst_0_4_F"), '')::int as age_psns_att_educ_inst_0_4_f,
nullif(trim("Age_psns_att_educ_inst_0_4_P"), '')::int as age_psns_att_educ_inst_0_4_p,

nullif(trim("Age_psns_att_educ_inst_5_14_M"), '')::int as age_psns_att_educ_inst_5_14_m,
nullif(trim("Age_psns_att_educ_inst_5_14_F"), '')::int as age_psns_att_educ_inst_5_14_f,
nullif(trim("Age_psns_att_educ_inst_5_14_P"), '')::int as age_psns_att_educ_inst_5_14_p,

nullif(trim("Age_psns_att_edu_inst_15_19_M"), '')::int as age_psns_att_edu_inst_15_19_m,
nullif(trim("Age_psns_att_edu_inst_15_19_F"), '')::int as age_psns_att_edu_inst_15_19_f,
nullif(trim("Age_psns_att_edu_inst_15_19_P"), '')::int as age_psns_att_edu_inst_15_19_p,

nullif(trim("Age_psns_att_edu_inst_20_24_M"), '')::int as age_psns_att_edu_inst_20_24_m,
nullif(trim("Age_psns_att_edu_inst_20_24_F"), '')::int as age_psns_att_edu_inst_20_24_f,
nullif(trim("Age_psns_att_edu_inst_20_24_P"), '')::int as age_psns_att_edu_inst_20_24_p,

nullif(trim("Age_psns_att_edu_inst_25_ov_M"), '')::int as age_psns_att_edu_inst_25_ov_m,
nullif(trim("Age_psns_att_edu_inst_25_ov_F"), '')::int as age_psns_att_edu_inst_25_ov_f,
nullif(trim("Age_psns_att_edu_inst_25_ov_P"), '')::int as age_psns_att_edu_inst_25_ov_p,

nullif(trim("High_yr_schl_comp_Yr_12_eq_M"), '')::int as high_yr_schl_comp_yr_12_eq_m,
nullif(trim("High_yr_schl_comp_Yr_12_eq_F"), '')::int as high_yr_schl_comp_yr_12_eq_f,
nullif(trim("High_yr_schl_comp_Yr_12_eq_P"), '')::int as high_yr_schl_comp_yr_12_eq_p,

nullif(trim("High_yr_schl_comp_Yr_11_eq_M"), '')::int as high_yr_schl_comp_yr_11_eq_m,
nullif(trim("High_yr_schl_comp_Yr_11_eq_F"), '')::int as high_yr_schl_comp_yr_11_eq_f,
nullif(trim("High_yr_schl_comp_Yr_11_eq_P"), '')::int as high_yr_schl_comp_yr_11_eq_p,

nullif(trim("High_yr_schl_comp_Yr_10_eq_M"), '')::int as high_yr_schl_comp_yr_10_eq_m,
nullif(trim("High_yr_schl_comp_Yr_10_eq_F"), '')::int as high_yr_schl_comp_yr_10_eq_f,
nullif(trim("High_yr_schl_comp_Yr_10_eq_P"), '')::int as high_yr_schl_comp_yr_10_eq_p,

nullif(trim("High_yr_schl_comp_Yr_9_eq_M"), '')::int as high_yr_schl_comp_yr_9_eq_m,
nullif(trim("High_yr_schl_comp_Yr_9_eq_F"), '')::int as high_yr_schl_comp_yr_9_eq_f,
nullif(trim("High_yr_schl_comp_Yr_9_eq_P"), '')::int as high_yr_schl_comp_yr_9_eq_p,

nullif(trim("High_yr_schl_comp_Yr_8_belw_M"), '')::int as high_yr_schl_comp_yr_8_belw_m,
nullif(trim("High_yr_schl_comp_Yr_8_belw_F"), '')::int as high_yr_schl_comp_yr_8_belw_f,
nullif(trim("High_yr_schl_comp_Yr_8_belw_P"), '')::int as high_yr_schl_comp_yr_8_belw_p,

nullif(trim("High_yr_schl_comp_D_n_g_sch_M"), '')::int as high_yr_schl_comp_d_n_g_sch_m,
nullif(trim("High_yr_schl_comp_D_n_g_sch_F"), '')::int as high_yr_schl_comp_d_n_g_sch_f,
nullif(trim("High_yr_schl_comp_D_n_g_sch_P"), '')::int as high_yr_schl_comp_d_n_g_sch_p,

nullif(trim("Count_psns_occ_priv_dwgs_M"), '')::int as count_psns_occ_priv_dwgs_m,
nullif(trim("Count_psns_occ_priv_dwgs_F"), '')::int as count_psns_occ_priv_dwgs_f,
nullif(trim("Count_psns_occ_priv_dwgs_P"), '')::int as count_psns_occ_priv_dwgs_p,

nullif(trim("Count_Persons_other_dwgs_M"), '')::int as count_persons_other_dwgs_m,
nullif(trim("Count_Persons_other_dwgs_F"), '')::int as count_persons_other_dwgs_f,
nullif(trim("Count_Persons_other_dwgs_P"), '')::int as count_persons_other_dwgs_p

from {{ source('bronze','census_g01') }}
where "LGA_CODE_2016" is not null