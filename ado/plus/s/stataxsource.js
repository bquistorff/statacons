 /*
    Developed by E. F. Haghish http://www.haghish.com/
    Center for Medical Biometry and Medical Informatics
    University of Freiburg, Germany
    haghish@imbi.uni-freiburg.de
    for documentation visit http://www.haghish.com/statax
    
    
    This program was developed for SHJS engine to highlight Stata syntax
    http://shjs.sourceforge.net/doc/gplv3.html
 */ 

if (! this.sh_languages) {this.sh_languages = {};}
sh_languages['stata'] = [
    [[/\/\/\//g,'sh_comment',1],
    [/\*\*/g,'sh_comment',7],
    //[/ \*/g,'sh_comment',7],		//for multiplication
    //[/\* /g,'sh_comment',7],		//for multiplication
    [/\*a/g,'sh_comment',7],
    [/\*A/g,'sh_comment',7],
    [/\*b/g,'sh_comment',7],
    [/\*B/g,'sh_comment',7],
    [/\*c/g,'sh_comment',7],
    [/\*C/g,'sh_comment',7],
    [/\*d/g,'sh_comment',7],
    [/\*D/g,'sh_comment',7],
    [/\*e/g,'sh_comment',7],
    [/\*E/g,'sh_comment',7],
    [/\*f/g,'sh_comment',7],
    [/\*F/g,'sh_comment',7],
    [/\*g/g,'sh_comment',7],
    [/\*G/g,'sh_comment',7],
    [/\*h/g,'sh_comment',7],
    [/\*H/g,'sh_comment',7],
    [/\*i/g,'sh_comment',7],
    [/\*I/g,'sh_comment',7],
    [/\*j/g,'sh_comment',7],
    [/\*J/g,'sh_comment',7],
    [/\*k/g,'sh_comment',7],
    [/\*K/g,'sh_comment',7],
    [/\*l/g,'sh_comment',7],
    [/\*L/g,'sh_comment',7],
    [/\*m/g,'sh_comment',7],
    [/\*M/g,'sh_comment',7],
    [/\*n/g,'sh_comment',7],
    [/\*N/g,'sh_comment',7],
    [/\*o/g,'sh_comment',7],
    [/\*O/g,'sh_comment',7],
    [/\*p/g,'sh_comment',7],
    [/\*P/g,'sh_comment',7],
    [/\*q/g,'sh_comment',7],
    [/\*Q/g,'sh_comment',7],
    [/\*r/g,'sh_comment',7],
    [/\*R/g,'sh_comment',7],
    [/\*s/g,'sh_comment',7],
    [/\*S/g,'sh_comment',7],
    [/\*t/g,'sh_comment',7],
    [/\*T/g,'sh_comment',7],
    [/\*u/g,'sh_comment',7],
    [/\*U/g,'sh_comment',7],
    [/\*v/g,'sh_comment',7],
    [/\*V/g,'sh_comment',7],
    [/\*w/g,'sh_comment',7],
    [/\*W/g,'sh_comment',7],
    [/\*x/g,'sh_comment',7],
    [/\*X/g,'sh_comment',7],
    [/\*y/g,'sh_comment',7],
    [/\*Y/g,'sh_comment',7],
    [/\*z/g,'sh_comment',7],
    [/\*Z/g,'sh_comment',7],
    [/\/\//g,'sh_comment',7],
    [/\/\*/g,'sh_comment',8],
    [/\/\*/g,'sh_comment',9],
    
    [
/\b(?:adoupdate|install|ssc|adgakern|synlight|markdoc|weave|close|div|txt|img|tble|misstable|bhatmesd|sysuse|scatter|forval|bcvwarpw|bcloglog|autosmoo|atkinson|asurvcrv|asserteq|altitude|adgaker2|xriqtest|xri_slll|xri_pnll|xri_mpll|xri_mell|xri_enll|xi_mkun2|warpstep|warpdens|warpdenm|venndiag|varxplor|urnmodel|unlabeld|unitroot|unilogit|trpoislf|trimblnk|trigamma|svy_preg|svy_pars|svy_olog|svy_logt|stmfracp|stcoxtvc|stcoxplt|stb_qihh|stb_next|stb_list|stb_find|stb_dtl1|stb_dtl0|stb_dirs|st_rpool|splitstr|sm4253eh|sktestdc|similari|silvtest|scenario|rxrmkdta|rpoisson|roblowes|rfprobit|rfpr_ll1|reshape2|resample|replword|relsgini|regpred2|ranksum2|r_ltnrml|qsortidx|qa_drive|qa_dense|qa_clear|qa_begin|qa__exit|ptransdb|projdate|probpred|printlog|postclos|post_zap|poisson2|plotrds2|permband|parsoptp|parcoord|overlapi|npresent|notefile|nmissing|nlsm_rpt|nlsm_epu|namemnth|mypoislf|mx_model|multnorm|msurface|mpredict|mountain|mnthname|mkbilogn|mfracpol|metabias|mergedct|mdytodow|lrcotest|lorobwei|logistat|logiodds|logiodd2|logdummy|lintrend|lastbday|labgraph|l2cvwarw|l2cvwarp|kornbrot|kerntriw|kerntria|kernquar|kerngaus|inflogit|ineqdeco|ineqdec0|implogit|idatetof|iclassr2|hreg2sls|hpfilter|hlmakfun|hlbivnor|heckpbtl|gwarpreg|grlexis2|gpredict|glmlogis|gaussgen|ftoidate|friedman|frac_sel|frac_rep|frac_ord|forgraph|fitpower|firstocc|findsmpl|finddate|filldate|faketemp|extrname|extlogit|exercise|example5|example4|example3|example2|example1|epoisson|dropoper|domdiver|diflogen|destring|defntion|datevars|date2obs|dagumfit|dagum_ll|cwhetero|cw_yesno|cw__find|cw__exer|cw__chap|cw__book|cpoisson|cosdetra|corrprob|conv2num|collfreq|colldiag|cnpoislf|centcalc|briertst|boxdetra|boxdetr2|bhatplot|bcvwarp|bartcdf|anyproc|amemiya|aflogit|adjprop|adjmean|addnote|zippred|zinbreg|zinb_ll|z_rvrfy|z_rcopy|ystrday|xri_nll|xmerged|xi_mkun|xi_eicu|wsanova|wntestf|winshow|wcotest|warpreg|warpoly|warping|warpden|vserteq|varrank|varorth|varnull|varcond|var_key|var_get|unblock|trpois0|trnbin0|trigami|triatex|tidwell|testsum|testres|tauprob|tabrate|t_print|switchr|svy_reg|survtab|sumdist|sturng8|sturng7|sturng6|sturng5|sturng4|sturng3|sturng2|sturng1|stlexis|stfracp|stb_sys|stb_sel|stb_qih|stb_idx|stb_dtl|stb_clr|stb_cal|staalen|srecode|smtwice|slrplot|sktestd|sktest2|simplex|setfwid|sampsiz|sampsi2|sample2|safetob|rxrsimu|rxrrisk|rxrmaxl|rxridge|rxrcrlq|running|rspread|rndpoix|rndivgx|rndgamx|rndbinx|rmttest|replstr|regpred|regmsng|regdiag|readtok|r_unfrm|r_lnrml|r_cnrml|qsturng|qa_text|qa_err2|qa_ans2|qa__zap|pwcorrs|pswdiff|predlog|prcompw|prcmp3x|prcmp2x|prcmp1x|prcmp0x|poverty|povdeco|post_fl|phtest2|phtest1|phscore|pearson|pattern|partres|parmest|overlap|outreg5|omscore|ocrpred|ocratio|numdays|notedit|nlsm_mu|nlaphea|nicenum|nbinreg|nbin0lf|namedow|mx_marq|mwstati|movsumm|modltbl|mlcoint|ml_heck|mkquant|mixcase|metareg|metainf|metacum|mergein|mcompr3|mcompr2|mcompr1|matrank|matrand|matorth|matnull|matnorm|matginv|matcond|mat2mac|lw_unit|lw_gfmt|ltablem|lspline|lrtest2|loopdef|logsumm|logpred|logopen|logifit|lin_m6r|limport|lexport|lastday|labedit|kernsim|kernreg|kernepa|kerneld|kerncos|johnson|infilen|inequal|ineqfac|iclassr|hlclean|hhcount|hh_slct|heckpbt|gwrgrid|growthi|gr3save|gphsave|gologit|glcurve|genvsum|geivars|gamplot|fpgraph|fpderiv|fpcurve|fitline|fisheri|findobs|findlag|findbug|fcnplot|exprcmd|exchstr|eprobit|epiconf|ehcvsrc|dtainfo|dstndiz|downame|dispcon|discrim|digamma|days360|datelab|cw_qnir|cw_more|cw__xeq|csunits|corcori|coranal|conhull|condraw|concord|compobs|compdta|clrscrn|chksumm|cenpois|cascade|bsmplot|browsew|bringin|boxcoxr|boxcoxg|bailey|atrgph|arpois|amstat|amoeba|alpha2|adjksm|addtex|acplot|accrue|zipois|zip_ll|z_rplt|z_rcii|yrxlab|xrigls|xparse|xmerge|xi_eii|xi_eic|winset|vorder|violin|varset|univar|tvprob|tspred|tsmult|tsload|tryrej|tmerge|tgraph|textab|tester|t_text|t_menu|t_fval|t_fpar|t_form|t_drop|t_crcs|suprob|sttody|strepl|stegen|stcoxe|stb_ex|st_aux|spline|spbase|sp_adj|simula|simul2|simple|robvar|robksm|rndwei|rndpoi|rndlgn|rndivg|rndgam|rndexp|rndchi|rndbin|ridder|report|ranova|ramsey|ralloc|r_nrml|r_chi2|quandt|qdagum|qa_xeq|qa_err|qa_ask|qa_ans|pyears|prcomp|prcmp4|prcmp3|prcmp2|prcmp1|prcmp0|ppunit|powell|poisml|poilog|plot3d|pgmhaz|pgm_ll|period|pdagum|pciest|outreg|omodel|obrien|numode|nonlin|nmatch|nlsm_s|nlsm_m|nlsm_h|nlsm_e|nbinlf|mx_mx1|mv2snp|minlen|mhrate|memset|memchk|mcross|mcompp|matsum|matmin|matmax|manova|makfun|lstand|lpartr|lorenz|loglin|linest|lfitx2|knnreg|jumble|jknife|hinflu|hidlin|hhcorr|header|hbolic|hansen|gumbel|growth|gr3use|gr3set|gphprt|genhwi|funnel|fpshow|fpplot|fisher|esarea|equipi|equimi|elapse|effmod|dyrate|dtdiff|digami|dickey|diablo|cw_use|cusumb|corcor|chplot|chkdup|censor|browse|brier2|boxtid|bisect|biprob|bartq|bandw|anydx|akapm|z_rci|xriml|xi_ei|xfrac|tsreg|tsfit|today|tobin|tab2i|t_num|t_def|t2way|sttvc|stkap|stats|stage|spear|sortd|smrby|smfit|sm_ll|slice|savin|rndbb|regmv|reghv|r_exp|quasi|qsort|nwest|null2|null1|nptri|npt_s|nbgof|myols|mx_lf|mx_d1|mx_d0|monte|modti|mlfit|metap|metan|mcc3i|maxr2|mateq|lwald|lotus|lnsim|lftbl|lexis|labbe|l1way|ktau2|iptab|ifexp|hreg2|hltex|hhtab|hhset|hh_is|grvar|gphwp|gphdt|genhw|galbr|fpgen|equip|equim|eqmat|ellip|dtadd|diest|crlad|confx|coll2|coint|chkdp|byvar|brset|bound|binsm|besd|xtab|with|win2|win1|wgap|vbar|tabw|smri|s_no|rndt|rndf|repl|regh|redo|pbis|nptr|norm|nlsm|modt|modl|meta|loop|lead|ldev|keyb|jtoe|invt|gr3q|goll|gmci|glmr|glmp|genl|for3|for2|fig3|fig2|fig1|expr|etoj|etab|dymh|dups|doit|defv|chow|brsq|breg|z_r|tci|stb|smr|seq|roc|r_t|qsm|psm|phi|pca|mca|lag|iqr|iov|hhi|gwr|gr3|gr2|gr1|gof|gam|fpx|dif|cdf|bvs|br2|biv|ac|a2|tv|lw|fp|cw|bv|forvalues|xwindow|winhelp|program|foreach|window|progra|define|while|progr|whil|prog|forv|end|else|for|if|prcounts|prchange|mlogview|mlogtest|mlogplot|logclose|listcoef|_peunvec|prvalue|praccum|fitstat|_pepred|_pemarg|_pecats|_pebase|_peabbv|_pesum|_perhs|_peife|_pedum|xpost|prtab|prgen|brant|ts|histogram|select|variabl|t2title|t1title|shading|reverse|rescale|replace|r2title|r1title|percent|missing|l2title|l1title|fweight|density|b2title|b1title|yscale|ylabel|xscale|xlabel|vwidth|values|twoway|tlabel|saving|rscale|rlabel|normal|noaxis|margin|jitter|detail|define|border|ytick|xtick|using|ttick|title|rtick|label|clear|ylog|xlog|text|star|smcl|root|rlog|reps|rbox|note|noax|key4|key3|key2|key1|half|freq|dots|cell|_all|ylo|yla|xlo|xla|var|val|tla|row|rlo|rla|pie|pen|obs|gap|def|col|box|bor|bin|bar|alt|yt|ys|xt|xs|tt|ti|t2|t1|st|rt|rs|r2|r1|lo|l2|l1|hi|ba|b2|b1|t|p|o|m|g|d|b|stackreset|stackdepth|marksample|constraint|summarize|speekchk2|speedchk1|simulinit|showpoint|postclose|estimates|correlate|constrain|_xtrenorm|ztweib_5|ztvary_5|zttoct_5|ztspli_5|ztjoin_5|ztfill_5|ztereg_5|ztbase_5|zt_smp_5|zt_sho_5|zt_iss_5|zt_hcd_5|zinb_plf|zinb_llf|xtrere_p|xtreg_re|xtreg_ml|xtreg_fe|xtreg_be|xtrefe_p|xtps_ren|xtprobit|xtintreg|wilcoxon|weibul_p|weibu_sw|weib_lf0|wdupdate|wdatetof|unabbrev|tutorial|tut_wait|tsreport|tokenize|tobit_sw|testparm|tempname|tempfile|tabulate|symmetry|swprobit|swologit|svytotal|svyreg_p|svyratio|svyprobt|svyoprob|svylogit|svylog_p|svyivreg|svyintrg|svy_head|svy_dreg|svy_disp|survcurv|summariz|stphtest|stphplot|st_subid|st_promo|st_issys|spline_x|spikeplt|spearman|snapspan|signtest|signrank|shewhart|sfrancia|seperate|separate|scobi_sw|regriv_p|regres_p|regre_p2|quantile|probit_p|priorest|preserve|postfile|poisso_p|poiss_sw|poiss_lf|personal|outsheet|orthpoly|oprobitp|oprobi_p|oprob_sw|op_colnm|ologit_p|ologi_sw|nbreg_sw|nbreg_lf|nbreg_al|mvencode|mvdecode|mlvecsum|mlogit_p|mlmatsum|ml_searc|ml_repor|ml_rdgrd|ml_query|ml_model|ml_mlout|ml_hbhhh|ml_graph|ml_grad0|ml_geqnr|ml_enrr0|ml_enr0i|ml_egr0i|ml_eer0i|ml_edr0i|ml_edfr0|ml_edfp0|ml_ecr0i|ml_ebr0i|ml_ebhr0|ml_ebhh0|ml_ebh0q|ml_ebfr0|ml_ebfg0|ml_debug|ml_clear|ml_check|ml_bhhhs|mkspline|meqparse|md2debu_|md1debu_|matstrik|matcproc|lvr2plot|lpredict|logistic|logis_lf|lnorma_p|lnorm_sw|lnorm_lf|llogis_p|llogi_sw|linktest|leverage|ksmirnov|kdensity|kapmeier|kalarma1|intrg_ll|hetpr_lf|heckprob|heckpr_p|heckp_lf|heckma_p|grmeanby|gr_print|gprobi_p|gphprint|gompertz|gomper_p|gompe_sw|gnbreg_p|gnbreg_5|gnbre_lf|glogit_p|gettoken|genvmean|generate|gamma_sw|gamma_lf|ftowdate|fracpred|fracpoly|fracplot|frac_wgt|frac_mun|frac_dis|frac_ddp|frac_cox|frac_chk|frac_adj|frac_154|fpredict|estimate|drawnorm|disp_res|describe|debugbuf|corrgram|correlat|contract|constrai|compress|collapse|collaps4|codebook|cnreg_sw|clogl_sw|clogit_p|clogi_sw|checksum|bsampl_w|boxcox_p|bootsamp|bmemsize|biprobit|arima_dr|anovadef|acprplot|_wsrvcrv|_tx_mtr5|_tx_mtr4|_tx_mtr3|_tx_mtr2|_tx_mtr1|_tutends|_tsheadr|_ts_peri|_ts_pars|_ts_meqn|_ts_gdat|_ts_flag|_ts_dsmp|_sw_lik2|_subchar|_predict|_pred_se|_pred_me|_partset|_parsewt|_parsevl|_mfrmvec|_linemax|_ldrtest|_kalman1|_jprxrpa|_jprglwz|_jprglld|_jprglil|_jprglfl|_jprglef|_jprfpxo|_jprfptp|_jprfpse|_jprfprp|_jprfpre|_jprfppp|_jprfpmm|_jprfplx|_jprfpin|_jprfpgn|_jprfpfp|_jprfpdx|_jprfpdt|_invlist|_grmiss2|_grfirst|_gpctile|_gpctile|_gmedian|_gmdmean|_glmresd|_glmmapl|_glmmapf|_glmilnk|_gladder|_getrres|_fracwgt|_fracrep|_fracord|_fracmdp|_fracdis|_fracddp|_fraccox|_fracchk|_crczsku|_crcwsrv|_crcwsrv|_crcvarl|_crcunit|_crcunit|_crcunab|_crctmge|_crcswxx|_crcstep|_crcsrvc|_crcsrvc|_crcsrv2|_crcslbl|_crcshdr|_crcrsfl|_crcrnfd|_crcplst|_crcphdr|_crcnuse|_crcnuse|_crcnms2|_crcnlou|_crcmiss|_crcichi|_crcglil|_crcglil|_crcgldv|_crcexnt|_crcexnf|_crcexne|_crcexnd|_crcexnc|_crcexnb|_crcexna|_crcexn9|_crcexn8|_crcexn7|_crcexn6|_crcexn5|_crcexn4|_crcexn2|_crcexn1|_crceprs|_crcchkw|_crcchkt|_crcchi2|_crcbygr|_crcbygr|_crcbcrt|_crcause|_crcacnt|_crcacnt|_crc4fld|_crc2use|_cr1invt|_cr1form|_cpmatnm|_callerr|_3dsvusr|_3drshow|_3drproj|_3dmkdta|_3ddflts|_3daxtbl|_3daxout|_3daxmin|ztsum_5|ztset_5|ztgen_5|ztdes_5|ztcox_5|zt_is_5|zt_hc_5|zt_ct_5|zip_plf|zip_llf|xwindow|xttrans|xttobit|xttest0|xtrch_p|xtps_lf|xtps_fe|xtnbreg|xtnb_lf|xtnb_fe|xtlogit|xtint_p|xtgls_p|xtgee_p|xtcnt_p|xtbin_p|wntestq|wntestb|winexec|wilc_st|weibull|weib_lf|version|verinst|uniform|tut_chk|tsrevar|tokeniz|tobit_p|teststd|tempvar|tabulat|tabodds|tabdisp|sysmenu|symplot|swtobit|swoprbt|swlogit|swlogis|swcnreg|svytest|svyprop|svypois|svyolog|svymlog|svymean|svy_sub|svy_get|svy_est|survsum|summari|stsplit|streset|stcoxkm|stcox_p|st_smpl|st_show|st_note|sreturn|serrbar|sdtesti|scob_lf|safesum|rvpplot|rvfplot|runtest|restore|reshape|replace|renpfix|regress|ranksum|quietly|quadchk|qreg_sw|prtesti|printgr|predict|predict|prais_p|prais_e|pperron|poisson|poisgof|playsnd|pergram|pentium|outshee|outfile|oprobit|op_diff|op_comp|ologitp|old_ver|numlist|nptrend|noisily|nobreak|nlexp2a|newey_p|ml_plot|ml_init|ml_exde|ml_elfs|ml_elfi|ml_defd|ml_adjs|memsize|matname|markout|lsens_x|lookfor|loneway|logrank|loglogs|logit_p|lnskew0|lnormal|llogist|kwallis|istdize|ipolate|invnorm|inspect|insheet|hprobit|hettest|hetprob|hetpr_p|helpchk|heckman|heck_d2|hausman|hadimvo|greigen|gprobit|gomp_lf|glmpred|gladder|genrank|generat|gamma_p|ftodate|fracgen|frac_xo|frac_pv|frac_pq|frac_pp|frac_in|frac_dv|execute|estimat|ereg_sw|ereg_lf|dstdize|dprobit|dotplot|display|discard|dfuller|describ|datetof|ctst_st|cscript|cprplot|coxbase|correla|constra|confirm|compare|cloglog|clogitp|clog_lf|centile|capture|canon_p|c_local|bsample|bprobit|bitesti|bipr_lf|bipp_lf|bcskew0|avplots|arima_p|arch_dr|adopath|_tx_rpl|_ttest2|_ttest2|_ttest1|_ttest1|_sw_ood|_sw_lik|_robust|_robksm|_rmcoll|_result|_repart|_pctile|_ksmwrk|_inlist|_gtrank|_gsrank|_grmiss|_grmean|_grlast|_grank2|_gmdmed|_glmwgt|_glmrpt|_ggroup|_ggroup|_getrhs|_gcount|_fracxo|_fracxo|_fracpv|_fracpp|_fracpp|_fracin|_fracdv|_evlist|_diparm|_crcseq|_crcmeq|_crcmeq|_crcksm|_crcirr|_crcird|_crccip|_crcbin|_crcar1|_bsqreg|_adjksm|__GEEUC|__GEERC|__GEEBT|_3dshad|_3dproj|_3dmnmx|ztir_5|xwindo|xtrchh|xtpred|xtpois|xthaus|xtdata|xtcorr|xtclog|xt_tis|xt_iis|xchart|window|versio|update|typeof|ttesti|tsunab|tsfill|tokeni|testnl|tabula|tabdis|tab_or|sysdir|syntax|swweib|swqreg|swpois|swereg|svytab|svyset|svyreg|svydes|summar|subwin|stweib|stvary|sttoct|sttocc|strate|stjoin|stinit|stfill|stereg|stcurv|stbase|st_set|st_hcd|sretur|smooth|sktest|search|sdtest|scobit|scob_p|scalar|sampsi|sample|rreg_p|rotate|return|repeat|rename|regres|reg3_p|recode|recast|rchart|quietl|qreg_p|qreg_c|qqplot|pwcorr|prtest|probit|predic|plugin|pctile|pchart|ovtest|outshe|outfil|orthog|oprobi|op_str|op_inv|oneway|ologit|notify|noisil|nlpred|nllog4|nllog3|nlinit|nlgom4|nlgom3|nlexp3|nlexp2|mrdu0_|mlopts|mlogit|mleval|ml_s_e|ml_opt|ml_nb0|ml_max|ml_log|ml_inv|ml_hd0|ml_elf|ml_eds|ml_e0i|ml_cnt|ml_c_d|mhodds|memory|mdytof|mdytoe|matrix|mantel|ltable|lrtest|lookup|lincom|lfit_p|ladder|kapwgt|joinby|intreg|inspec|inshee|infile|impute|hlogit|hilite|grebar|gphpen|gphdot|gnbreg|glogit|global|glm_sw|genstd|genera|ftomdy|format|for5_0|fillin|factor|export|expand|execut|etomdy|etodow|estima|ereg_p|encode|eivreg|dynren|dwstat|doedit|displa|disp_s|dfbeta|descri|decode|cttost|ctst_5|coxvar|coxhaz|cox_sw|correl|constr|confir|cnsreg|clogit|clog_p|clocal|cchart|bstrap|bsqreg|boxcox|blogit|bitowt|bitest|bipr_p|avplot|assert|areg_p|arch_p|append|aorder|adjust|_wkapm|_ttest|_ttest|_sfran|_opnum|_nlout|_newey|_mkvec|_maked|_isfit|_huber|_grsum|_grobs|_grmin|_grmax|_grank|_grank|_gmean|_glmfl|_gfill|_gfill|_getbv|_gdiff|_cu_c0|_crcrr|_crcrd|_crcra|_crcor|_crcor|_crclf|_crcci|_cr1se|_byobs|_addop|_3dax0|zts_5|zip_p|zap_s|xwind|xttab|xtsum|xtreg|xtile|xtgls|xtgee|xtdes|xpose|xcorr|wmenu|windo|which|whelp|wdctl|versi|ttest|tsset|touch|token|tobit|timer|tabul|table|tabdi|symmi|swilk|swcox|svylc|svy_x|svmat|sureg|summa|stsum|stset|streg|stgen|stdes|stcox|stack|st_is|st_hc|st_ct|sretu|sqreg|sleep|simul|shell|score|scala|rotat|retur|renam|remap|regre|regdw|range|quiet|query|qnorm|prove|probi|predi|prais|popup|pnorm|plugi|pcorr|pause|parse|outsh|outfi|order|oprob|onewa|ologi|notes|noisi|newey|nbreg|mvreg|mnl0_|mlsum|mlogi|ml_e2|ml_e1|ml_e0|mkmat|mkdir|merge|means|matri|macro|lstat|lsens|looku|logit|local|kappa|kap_3|ivreg|iqreg|integ|inspe|inshe|input|infix|infil|hotel|hereg|hareg|gwood|gsort|graph|globa|glm_p|gener|gamma|forma|facto|execu|estim|error|erase|encod|emdef|dynre|doedi|displ|descr|decod|debug|dbeta|cusum|cumul|cumsp|ctset|ct_is|cross|cox_p|count|corre|const|confi|cnreg|clogi|clear|cksum|chdir|canon|bstat|brier|break|asser|arima|appen|anova|alpha|about|_qreg|_nobs|_mvec|_hube|_gtma|_gsum|_gstd|_grsd|_gmtr|_gmtr|_gmin|_gmax|_gmad|_giqr|_gcut|_crct|_cr1t|_addl|zinb|xwin|wind|whic|wdlg|vwls|vers|unab|type|tset|trim|tobi|test|tabu|tabi|tabd|tab2|tab1|summ|stmh|stmc|stir|stem|sret|sqrt|sort|shel|scor|scal|save|rreg|rota|retu|rena|regr|reg3|rcof|quie|quer|qreg|qchi|push|prob|pred|post|popu|plug|plot|pchi|pars|outs|outf|opro|onew|olog|nois|nl_p|news|move|more|mlog|mlf_|ml_5|merg|md2_|md1_|md0_|mcci|matr|mark|macr|lroc|look|logi|loca|list|lfit|labe|ktau|keep|insp|insh|inpu|infi|hreg|hist|help|grap|glob|gene|ftoe|form|fact|exit|exec|etof|esti|erro|ereg|enco|egen|edit|dydx|drop|doed|disp|desc|deff|deco|coun|corr|corc|copy|cons|conf|cnre|clog|char|boot|beep|asse|args|areg|arch|appe|anov|_svy|_hub|_gsd|_gma|zip|win|whi|vif|vce|use|typ|tob|tis|tes|te|tab|sum|sts|sor|she|set|sds|sco|sca|say|sav|run|rot|ret|ren|reg|qui|que|qby|pwd|pro|pop|plo|par|pac|out|opr|one|olo|noi|net|mov|mor|mer|mcc|mat|man|mac|loo|log|loc|lis|lab|ksm|kap|iri|ins|inp|inf|iis|hlu|hel|gra|gph|glo|glm|gen|fit|fft|fac|exi|est|err|enc|edi|doe|dis|dir|des|dec|csi|crc|cox|cou|cor|cnr|clo|cii|cci|cat|cap|bee|ass|app|ano|ado|_ts|_hu|_ac|xi|wh|us|ty|ta|sw|su|st|so|sh|se|sa|ru|rm|qu|pr|pl|ou|no|nl|ml|ma|lv|ls|lo|li|la|ir|in|he|gr|gl|ge|ex|eq|en|ed|ds|do|di|de|ct|cs|cp|ci|cf|cd|cc|by|bs|be|as|ap|an|u|q|n|l|h|g|e|d|_gclsort|_gpcrank|_gprod|_gprop-_gpc|_grmedf|_grpos|_grprod|_gslope|_gsoundex|_gwtmean|abar|acplot|addtex|addtxt|adjacent|adjksm|adjmean|adjprop|adjust|adoedit|adotype|allcross|allpossible|alphawgt|anovaplot|archlm|areg2|arimafit|autolog|avplot2|avplot3|barplot|barplot2|bcoeff|betacoef|betafit|bgtest|bigtab|biplot|biprob|bking|blist|blogit2|bnormpdf|boolean|bpagan|bpass|bspline|bygap|bys|byvar|canon|catdev|catenate|catgraph|catplot|cb2html|ccweight|cenpois|centcalc|center|centroid|cf2|cf3|cflpois|chaos|charlist|charutil|checkvar|chiplot|ci2|cibplot|cid|ciform|cihplot|cij|ciplot|cipolate|circular|cistat|civplot|ciw|cleanlog|clemao_io|cltest|cluster|cme|cndnmb3|cnsrsig|codebook2|coldiag|colelms|collapse2|collapseunique|concord|confirmdir|confsvy|contrast|copydesc|coranal|corr_svy|corrtab|cortesti|cpcorr|cpr|cpyxplot|crtest|csjl|ctabstat|cusum6|cvxhull|cycleplot|dagumfit|dashgph|dashln|datelist|datesum|datmat|decomp|decompose|denton|descsave|desmat|detect|dfao|dfgls|diagt|diagtest|disjoint|dissim|distan|distinct|distplot|dmariano|dmerge|dmexogxt|dolog|dologx|domdiag|dotex|doub2flt|doubmass|dpplot|ds2|ds3|ds5|dsconcat|dsearch|dtobit2|dummies|dups|durbinh|eba|ebb|eclplot|effects|egenmore|elapse|ellip|ellip6|ellip7|enlarge|epiconf|epsigr|eqprhistogram|estout|estsave|etime|ewma|examples|expandby|expgen|explist|extremes|factext|factmerg|factortest|factref|far5|fastcd|fbar|fedit|feldti|finddup|findval|fitmacro|fitstat|flower|fndmtch|fndmtch2|fodstr|for211|forfile|fracdiff|fracirf|fs|fsum|full_palette|fulltab|gammafit|gammasym|gby|gcause|geivars|geneigen|genfreq|genhwcci|gentrun|genvars|ghistcum|ginidesc|gipf|glcurve|glcurve7|gllamm|glmcorr|gmci|gmlabvpos|gologit|gpfobl|gphepssj|gphudak|gprefscode|gpreset|grand|grand2|grby|grfreq|grlogit|grnote|groups|grqreg|gumbelfit|gwhet|hadrilm|hansen2|hapblock|hapipf|harmby|hausman|hbar|hbox|hcaccprox|heckman2|heckprob2|hegy4|hetprob|himatrix|hireg|hist3|histbox|histplot|hlist|hlpdir|hotdeck|hplot|hshaz|icomp|idonepsu|iia|inccat|indexplot|ineq|ineqdec0|ineqdeco|ineqfac|inequal2|inequal7|ingap|intext|intterms|ipf|ipshin|irrepro|isco|isko|istdize|ivendog|ivglog|ivgmm0|ivhettest|ivprob-ivtobit|ivreg2|jb|jb6|johans|jonter|kapgof|kdbox|kdensity|kdmany|kernreg1|kernreg2|keyplot|kpss|kr20|kwallis2|labsort|labsumm|labutil|lambda|latab|levels|levene|levinlin|lfsum|lincom2|lincomest|linkplot|listtex|listutil|ljs|lmoments|lms|loevh|log2do2|log2html|logpred|lomodrs|longch|longplot|lookforit|loopplot|lprplot|lrchg|lrdrop1|lrmatx|lrplot|lrseq|lrutil|lstack|ltable2|madfuller|majority|makematrix|maketex|margfx|marker|markov|mat2txt|matmap|matodd|matrixof|matvsort|mca|mcl|mcqscore|mdensity|median|medoid|meta_lr|metaaggr|metabias|metafunnel|metaninf|metatrim|mfilegr|mgen|minap|missing|mitools|mkbilogn|mkcorr|mkdat|mkstrsn|mktab|mlcoint|mlogpred|mmerge|mnthplot|modlpr|moreobs|mrdum|mrtab|msp|msplot|mstdize|mstore|muxplot|muxyplot|mvcorr|mvprobit|mvsamp1i|mvsampsi|mvsumm|mvtest|mylabels|mypkg|nbfit|nbinreg|ncf|nct|nearest|nearmrg|newey2|nharvey|nicedates|nnest|nnmatch|normtest|nproc|ocratio|ofrtplot|omninorm|omodel|onewayplot|onewplot|oprobpr|ordplot|orthog|outdat|outfix|outfix2|outreg|outreg5|outseries|outtable|outtex|overid|overidxt|overlay|ovfplot|pairplot|panelauto|panelunit|pantest2|parmest|parplot|partgam|pbeta|pcontract|pcorr2|pexp|pgamma|pgmhaz8|plotmatrix|pnrcheck|poisml|povdeco|poverty|powercal|ppplot|predcalc|predxcat|predxcon|printgph|probexog-tobexog|probitiv|psbayes|psmatch2|ptrend|pwcorrs|pwcorrw|pweibull|pwploti|pyramid|qbeta|qexp|qfrplot|qgamma|qhapipf|qlognorm|qqplot2|qrowname|qsim|quantil2|qweibull|ralloc|ranova|ranvar|raschcvt|raschtest|rbounds|rdplot|readlog|recast2|recode2|reformat|reg3|regaxis|reglike|regplot|regpred|regresby|renames|reshape8|rfregk|rglm|rgroup|rhetplot|rmanova|rnd|roblpr|rocss|rollreg|rowranks|rowsort|rvfplot2|rvlrplot|rvpplot2|safedrop|savasas|savesome|sbplot|sbplot5|sbrowni|sdecode|sdtest|seg|selectvars|sencode|senspec|seq|sf36|shapley|shortdir|showgph|shownear|skewplot|slideplot|slist|smfit|smhsiao|smileplot|soepren|somersd|soreg|sortlistby|spaces|sparl|spell|spellutil|sphdist|spikeplt|split|splitvallabels|spsurv|sq|ssizebi|sskapp|sssplot|stack|stak|statsbyfast|statsmat|stbget|stbtcalc|stcascoh|stcmd|stcompet|stcoxgof|stcoxplt|stcstat|stcumh|stexpect|stgtcalc|stkerhaz|sto|storecmd|stpiece|stpm|stquant|strdate|strgen|strip|strparse|stselpre|studysi|sumdist|summdate|summvl|sunflower|suprob|survtime|survwgt|sutex|svmatf|svr|svvarlbl|svybs|svytabs|swapval|swblock|swboot|switchr|symmetry|t2way5|tab2way|tab3way|tab_chi|taba|tabcond|tabcount|tabhbar|tabhplot|tablab|tablecol|tablepc|tableplot|tabmerge|tabplot|tabstatmat|tarow|textgph|tgraph|title|tknz|tmpdir|tobitiv|todate|tolower|tomode|torats|torumm|tosql|tpred|tpvar|trinary|triplot|triprobit|trnbin0|trpois0|tryem|tscollap|tsgraph|tslist|tsmktim|tsplot|tsspell|twoway_estfit|unique|unitab|univar|univstat|usagelog|usesas|vallab|vallist|vanelteren|varcase|varlab|varlag|vartyp|vecar|vecar6|vececm|venndiag|violin|vlist|vmatch|vplplot|vreverse|vtokenize|wbull|wclogit|wgttest|whitef|whitetst|whotdeck|williams|winsor|wntstmvq|xcollapse|xcontract|xcorplot|xfrac|xi3|xpredict|xrigls|xriml|xsampsi|xtab|xtabond2|xtgraph|xtile2|xtpattern|xttest2|xttest3|xttrans2|zandrews|zb_qrm|zinb|zip)\b/g,      'sh_keyword',
      -1
    ],
       
    [/(\+|--|\)|\])(\s*)(\/=?(?![*\/]))/g,['sh_symbol', 'sh_normal', 'sh_symbol'],-1],
    [/(0x[A-Fa-f0-9]+|(?:[\d]*\.)?[\d]+(?:[eE][+-]?[\d]+)?)(\s*)(\/(?![*\/]))/g,['sh_number', 'sh_normal', 'sh_symbol'],-1],
    [/([A-Za-z][A-Za-z0-9]*\s*)(\/=?(?![*\/]))/g,['sh_normal', 'sh_symbol'],],
    [/\/(?:\\.|[^*\\\/])(?:\\.|[^\\\/])*\/[gim]*/g,'sh_regexp',-1],
    [/\b[+-]?(?:(?:0x[A-Fa-f0-9]+)|(?:(?:[\d]*\.)?[\d]+(?:[eE][+-]?[\d]+)?))u?(?:(?:int(?:8|16|32|64))|L)?\b/g,'sh_number',-1],
    [/"/g,'sh_string',10],
 [/'/g,'sh_macro',11],
 [/`/g,'sh_macro',11],
 [/~|!|%|\^|\*|\(|\)|-|\+|=|\[|\]|\\|:|;|,|\.|\/|\?|&|<|>|\|/g,'sh_symbol',-1],
 [/\{|\}/g,'sh_cbracket',-1],
 [/\b(?:Math|Infinity|NaN|undefined|arguments)\b/g,'sh_predef_var',-1],
 [/\b(?:abs|acos|acosh|asin|asinh|atan|atan2|atanh|ceil|cloglog|comb|cos|cosh|digamma|exp|floor|int|invcloglog|invlogit|ln|lnfactorial|lngamma|log|log10|logit|max|min|mod|reldif|round|sign|sin|sinh|sqrt|sum|tan|tanh|trigamma|trunc|ibeta|betaden|ibetatail|invibeta|invibetatail|nibeta|nbetaden|invnibeta|binomial|binomialp|binomialtail|invbinomial|invbinomialtail|chi2|chi2den|chi2tail|invchi2|invchi2tail|nchi2|nchi2den|nchi2tail|invnchi2|invnchi2tail|npnchi2|dunnettprob|invdunnettprob|F|Fden|Ftail|invF|invFtail|nF|nFden|nFtail|invnFtail|npnF|gammap|gammaden|gammaptail|invgammap|invgammaptail|dgammapda|dgammapdada|dgammapdadx|dgammapdx|dgammapdxdx|hypergeometric|hypergeometricp|nbinomial|nbinomialp|nbinomialtail|invnbinomial|invnbinomialtail|binormal|normal|normalden|normalden|normalden|invnormal|lnnormal|lnnormalden|lnnormalden|lnnormalden|poisson|poissonp|poissontail|invpoisson|invpoissontail|t|tden|ttail|invt|invttail|nt|ntden|nttail|invnttail|npnt|tukeyprob|invtukeyprob|runiform|rbeta|rbinomial|rchi2|rgamma|rhypergeometric|rnbinomial|rnormal|rnormal|rnormal|rpoisson|rt|abbrev|char|indexnot|itrim|length|lower|ltrim|plural|proper|real|regexm|regexr|regexs|reverse|rtrim|soundex|soundex_nara|strcat|strdup|string|strlen|strlower|strltrim|strmatch|strofreal|strofreal|strpos|strproper|strreverse|strrtrim|strtoname|strtoname|strtrim|strupper|subinstr|subinword|substr|trim|upper|word|wordcount|autocode|byteorder|c|_caller|chop|clip|cond|e|epsdouble|epsfloat|fileexists|fileread|filereaderror|filewrite|float|fmtwidth|has_eprop|inlist|inrange|irecode|matrix|maxbyte|maxdouble|maxfloat|maxint|maxlong|mi|minbyte|mindouble|minfloat|minint|minlong|missing|r|recode|replay|return|s|scalar|smallestdouble|bofd|Cdhms|Chms|Clock|clock|Cmdyhms|Cofc|cofC|Cofd|cofd|daily|date|day|dhms|dofb|dofC|dofc|dofh|dofm|dofq|dofw|dofy|dow|doy|halfyear|halfyearly|hh|hhC|hms|hofd|hours|mdy|mdyhms|minutes|mm|mmC|mofd|month|monthly|msofhours|msofminutes|msofseconds|qofd|quarter|quarterly|seconds|ss|ssC|tC|tc|td|th|tm|tq|tw|week|weekly|wofd|year|yearly|yh|ym|yofd|yq|yw|tin|twithin|cholesky|corr|diag|get|hadamard|I|inv|invsym|J|matuniform|nullmat|sweep|vec|vecdiag|colnumb|colsof|det|diag0cnt|el|issymmetric|matmissing|mreldif|rownumb|rowsof|trace)\b/g,
 'sh_predef_func',
 -1
 ],
 [/(?:[A-Za-z]|_)[A-Za-z0-9_]*(?=[ \t]*\()/g,'sh_function',-1]
 ],
 [
 [/$/g,null,-2],
 [/(?:<?)[A-Za-z0-9_\.\/\-_~]+@[A-Za-z0-9_\.\/\-_~]+(?:>?)|(?:<?)[A-Za-z0-9_]+:\/\/[A-Za-z0-9_\.\/\-_~]+(?:>?)/g,'sh_url',-1],
 [/<\?xml/g,'sh_preproc',2,1],
 [/<!DOCTYPE/g,'sh_preproc',4,1],
 [/<!--/g,'sh_comment',5],
 [/<(?:\/)?[A-Za-z](?:[A-Za-z0-9_:.-]*)(?:\/)?>/g,'sh_keyword',-1],
 [/<(?:\/)?[A-Za-z](?:[A-Za-z0-9_:.-]*)/g,'sh_keyword',6,1],
 [/&(?:[A-Za-z0-9]+);/g,'sh_preproc',-1],
 [/<(?:\/)?[A-Za-z][A-Za-z0-9]*(?:\/)?>/g,'sh_keyword',-1],
 [/<(?:\/)?[A-Za-z][A-Za-z0-9]*/g,'sh_keyword',6,1],
 [/@[A-Za-z]+/g,'sh_type',-1],
 [/(?:TODO|FIXME|BUG)(?:[:]?)/g,'sh_todo',-1]
 ],
 [
 [/\?>/g,'sh_preproc',-2],
 [/([^=" \t>]+)([ \t]*)(=?)/g,['sh_type', 'sh_normal', 'sh_symbol'],-1],
    [/"/g,'sh_string',3]
 ],
 [[/\\(?:\\|")/g,null,-1],
    [/"/g,'sh_string',-2]
 ],
 [[/>/g,'sh_preproc',-2],
 [/([^=" \t>]+)([ \t]*)(=?)/g,
      ['sh_type', 'sh_normal', 'sh_symbol'],-1],
    [/"/g,'sh_string',3]
 ],
 [[/-->/g,'sh_comment',-2],[/<!--/g,'sh_comment',5]],
 [[/(?:\/)?>/g,'sh_keyword',-2],
 [/([^=" \t>]+)([ \t]*)(=?)/g,['sh_type', 'sh_normal', 'sh_symbol'],-1],
    [/"/g,'sh_string',3]
 ],
 [[/$/g,null,-2]],
 [
 [/\*\//g,'sh_comment',-2],
 [/(?:<?)[A-Za-z0-9_\.\/\-_~]+@[A-Za-z0-9_\.\/\-_~]+(?:>?)|(?:<?)[A-Za-z0-9_]+:\/\/[A-Za-z0-9_\.\/\-_~]+(?:>?)/g,'sh_url',-1],
 [/<\?xml/g,'sh_preproc',2,1],
 [/<!DOCTYPE/g,'sh_preproc',4,1],
 [/<!--/g,'sh_comment',5],
 [/<(?:\/)?[A-Za-z](?:[A-Za-z0-9_:.-]*)(?:\/)?>/g,'sh_keyword',-1],
 [/<(?:\/)?[A-Za-z](?:[A-Za-z0-9_:.-]*)/g,'sh_keyword',6,1],
 [/&(?:[A-Za-z0-9]+);/g,'sh_preproc',-1],
 [/<(?:\/)?[A-Za-z][A-Za-z0-9]*(?:\/)?>/g,'sh_keyword',-1],
 [/<(?:\/)?[A-Za-z][A-Za-z0-9]*/g,'sh_keyword',6,1],
 [/@[A-Za-z]+/g,'sh_type',-1],
 [/(?:TODO|FIXME|BUG)(?:[:]?)/g,'sh_todo',-1]
 ],
 [
 [/\*\//g,'sh_comment',-2],
 [/(?:<?)[A-Za-z0-9_\.\/\-_~]+@[A-Za-z0-9_\.\/\-_~]+(?:>?)|(?:<?)[A-Za-z0-9_]+:\/\/[A-Za-z0-9_\.\/\-_~]+(?:>?)/g,'sh_url',-1],
 [/(?:TODO|FIXME|BUG)(?:[:]?)/g,'sh_todo',-1]
 ],
 [[/"/g,'sh_string',-2],[/\\./g,'sh_specialchar',-1]],
  [[/`/g,'sh_macro',-2],[/'/g,'sh_macro',-2],[/\\./g,'sh_specialchar',-1]]
];


if (! this.sh_languages) {
  this.sh_languages = {};
}
var sh_requests = {};

function sh_isEmailAddress(url) {
  if (/^mailto:/.test(url)) {
    return false;
  }
  return url.indexOf('@') !== -1;
}

function sh_setHref(tags, numTags, inputString) {
  var url = inputString.substring(tags[numTags - 2].pos, tags[numTags - 1].pos);
  if (url.length >= 2 && url.charAt(0) === '<' && url.charAt(url.length - 1) === '>') {
    url = url.substr(1, url.length - 2);
  }
  if (sh_isEmailAddress(url)) {
    url = 'mailto:' + url;
  }
  tags[numTags - 2].node.href = url;
}

function sh_konquerorExec(s) {
  var result = [''];
  result.index = s.length;
  result.input = s;
  return result;
}

function sh_highlightString(inputString, language) {
  if (/Konqueror/.test(navigator.userAgent)) {
    if (! language.konquered) {
      for (var s = 0; s < language.length; s++) {
        for (var p = 0; p < language[s].length; p++) {
          var r = language[s][p][0];
          if (r.source === '$') {
            r.exec = sh_konquerorExec;
          }
        }
      }
      language.konquered = true;
    }
  }

  var a = document.createElement('a');
  var span = document.createElement('span');

  var tags = [];
  var numTags = 0;

  var patternStack = [];

  var pos = 0;

  var currentStyle = null;

  var output = function(s, style) {
    var length = s.length;
    if (length === 0) {
      return;
    }
    if (! style) {
      var stackLength = patternStack.length;
      if (stackLength !== 0) {
        var pattern = patternStack[stackLength - 1];
        if (! pattern[3]) {
          style = pattern[1];
        }
      }
    }
    if (currentStyle !== style) {
      if (currentStyle) {
        tags[numTags++] = {pos: pos};
        if (currentStyle === 'sh_url') {
          sh_setHref(tags, numTags, inputString);
        }
      }
      if (style) {
        var clone;
        if (style === 'sh_url') {
          clone = a.cloneNode(false);
        }
        else {
          clone = span.cloneNode(false);
        }
        clone.className = style;
        tags[numTags++] = {node: clone, pos: pos};
      }
    }
    pos += length;
    currentStyle = style;
  };

  var endOfLinePattern = /\r\n|\r|\n/g;
  endOfLinePattern.lastIndex = 0;
  var inputStringLength = inputString.length;
  while (pos < inputStringLength) {
    var start = pos;
    var end;
    var startOfNextLine;
    var endOfLineMatch = endOfLinePattern.exec(inputString);
    if (endOfLineMatch === null) {
      end = inputStringLength;
      startOfNextLine = inputStringLength;
    }
    else {
      end = endOfLineMatch.index;
      startOfNextLine = endOfLinePattern.lastIndex;
    }

    var line = inputString.substring(start, end);

    var matchCache = [];
    for (;;) {
      var posWithinLine = pos - start;

      var stateIndex;
      var stackLength = patternStack.length;
      if (stackLength === 0) {
        stateIndex = 0;
      }
      else {
        stateIndex = patternStack[stackLength - 1][2];
      }

      var state = language[stateIndex];
      var numPatterns = state.length;
      var mc = matchCache[stateIndex];
      if (! mc) {
        mc = matchCache[stateIndex] = [];
      }
      var bestMatch = null;
      var bestPatternIndex = -1;
      for (var i = 0; i < numPatterns; i++) {
        var match;
        if (i < mc.length && (mc[i] === null || posWithinLine <= mc[i].index)) {
          match = mc[i];
        }
        else {
          var regex = state[i][0];
          regex.lastIndex = posWithinLine;
          match = regex.exec(line);
          mc[i] = match;
        }
        if (match !== null && (bestMatch === null || match.index < bestMatch.index)) {
          bestMatch = match;
          bestPatternIndex = i;
          if (match.index === posWithinLine) {
            break;
          }
        }
      }

      if (bestMatch === null) {
        output(line.substring(posWithinLine), null);
        break;
      }
      else {
        if (bestMatch.index > posWithinLine) {
          output(line.substring(posWithinLine, bestMatch.index), null);
        }

        var pattern = state[bestPatternIndex];
        var newStyle = pattern[1];
        var matchedString;
        if (newStyle instanceof Array) {
          for (var subexpression = 0; subexpression < newStyle.length; subexpression++) {
            matchedString = bestMatch[subexpression + 1];
            output(matchedString, newStyle[subexpression]);
          }
        }
        else {
          matchedString = bestMatch[0];
          output(matchedString, newStyle);
        }

        switch (pattern[2]) {
        case -1:

          break;
        case -2:
          patternStack.pop();
          break;
        case -3:
          patternStack.length = 0;
          break;
        default:
          patternStack.push(pattern);
          break;
        }
      }
    }

    if (currentStyle) {
      tags[numTags++] = {pos: pos};
      if (currentStyle === 'sh_url') {
        sh_setHref(tags, numTags, inputString);
      }
      currentStyle = null;
    }
    pos = startOfNextLine;
  }

  return tags;
}



function sh_getClasses(element) {
  var result = [];
  var htmlClass = element.className;
  if (htmlClass && htmlClass.length > 0) {
    var htmlClasses = htmlClass.split(' ');
    for (var i = 0; i < htmlClasses.length; i++) {
      if (htmlClasses[i].length > 0) {
        result.push(htmlClasses[i]);
      }
    }
  }
  return result;
}

function sh_addClass(element, name) {
  var htmlClasses = sh_getClasses(element);
  for (var i = 0; i < htmlClasses.length; i++) {
    if (name.toLowerCase() === htmlClasses[i].toLowerCase()) {
      return;
    }
  }
  htmlClasses.push(name);
  element.className = htmlClasses.join(' ');
}

function sh_extractTagsFromNodeList(nodeList, result) {
  var length = nodeList.length;
  for (var i = 0; i < length; i++) {
    var node = nodeList.item(i);
    switch (node.nodeType) {
    case 1:
      if (node.nodeName.toLowerCase() === 'br') {
        var terminator;
        if (/MSIE/.test(navigator.userAgent)) {
            terminator = '\r';
        }
        else {
            terminator = '\n';
        }
        result.text.push(terminator);
        result.pos++;
      }
      else {
        result.tags.push({node: node.cloneNode(false), pos: result.pos});
        sh_extractTagsFromNodeList(node.childNodes, result);
        result.tags.push({pos: result.pos});
      }
      break;
    case 3:
    case 4:
      result.text.push(node.data);
      result.pos += node.length;
      break;
    }
  }
}

function sh_extractTags(element, tags) {
  var result = {};
  result.text = [];
  result.tags = tags;
  result.pos = 0;
  sh_extractTagsFromNodeList(element.childNodes, result);
  return result.text.join('');
}

function sh_mergeTags(originalTags, highlightTags) {
  var numOriginalTags = originalTags.length;
  if (numOriginalTags === 0) {
    return highlightTags;
  }

  var numHighlightTags = highlightTags.length;
  if (numHighlightTags === 0) {
    return originalTags;
  }

  var result = [];
  var originalIndex = 0;
  var highlightIndex = 0;

  while (originalIndex < numOriginalTags && highlightIndex < numHighlightTags) {
    var originalTag = originalTags[originalIndex];
    var highlightTag = highlightTags[highlightIndex];

    if (originalTag.pos <= highlightTag.pos) {
      result.push(originalTag);
      originalIndex++;
    }
    else {
      result.push(highlightTag);
      if (highlightTags[highlightIndex + 1].pos <= originalTag.pos) {
        highlightIndex++;
        result.push(highlightTags[highlightIndex]);
        highlightIndex++;
      }
      else {
        result.push({pos: originalTag.pos});

        highlightTags[highlightIndex] = {node: highlightTag.node.cloneNode(false), pos: originalTag.pos};
      }
    }
  }

  while (originalIndex < numOriginalTags) {
    result.push(originalTags[originalIndex]);
    originalIndex++;
  }

  while (highlightIndex < numHighlightTags) {
    result.push(highlightTags[highlightIndex]);
    highlightIndex++;
  }

  return result;
}

function sh_insertTags(tags, text) {
  var doc = document;

  var result = document.createDocumentFragment();
  var tagIndex = 0;
  var numTags = tags.length;
  var textPos = 0;
  var textLength = text.length;
  var currentNode = result;
  while (textPos < textLength || tagIndex < numTags) {
    var tag;
    var tagPos;
    if (tagIndex < numTags) {
      tag = tags[tagIndex];
      tagPos = tag.pos;
    }
    else {
      tagPos = textLength;
    }

    if (tagPos <= textPos) {
      if (tag.node) {
        var newNode = tag.node;
        currentNode.appendChild(newNode);
        currentNode = newNode;
      }
      else {
        currentNode = currentNode.parentNode;
      }
      tagIndex++;
    }
    else {
      currentNode.appendChild(doc.createTextNode(text.substring(textPos, tagPos)));
      textPos = tagPos;
    }
  }

  return result;
}

function sh_highlightElement(element, language) {
  sh_addClass(element, 'sh_sourceCode');
  var originalTags = [];
  var inputString = sh_extractTags(element, originalTags);
  var highlightTags = sh_highlightString(inputString, language);
  var tags = sh_mergeTags(originalTags, highlightTags);
  var documentFragment = sh_insertTags(tags, inputString);
  while (element.hasChildNodes()) {
    element.removeChild(element.firstChild);
  }
  element.appendChild(documentFragment);
}

function sh_getXMLHttpRequest() {
  if (window.ActiveXObject) {
    return new ActiveXObject('Msxml2.XMLHTTP');
  }
  else if (window.XMLHttpRequest) {
    return new XMLHttpRequest();
  }
  throw 'No XMLHttpRequest implementation available';
}
function sh_load(language, element, prefix, suffix) {
  if (language in sh_requests) {
    sh_requests[language].push(element);
    return;
  }

  sh_requests[language] = [element];
  var request = sh_getXMLHttpRequest();
  var url = prefix + 'sh_' + language + suffix;
  request.open('GET', url, true);
  request.onreadystatechange = function () {
    if (request.readyState === 4) {
      try {
        if (! request.status || request.status === 200) {
          eval(request.responseText);
          var elements = sh_requests[language];
          for (var i = 0; i < elements.length; i++) {
            sh_highlightElement(elements[i], sh_languages[language]);
          }
        }
        else {
          throw 'HTTP error: status ' + request.status;
        }
      }
      finally {
        request = null;
      }
    }
  };
  request.send(null);
}

function sh_highlightDocument(prefix, suffix) {
  var nodeList = document.getElementsByTagName('pre');
  for (var i = 0; i < nodeList.length; i++) {
    var element = nodeList.item(i);
    var htmlClasses = sh_getClasses(element);
    for (var j = 0; j < htmlClasses.length; j++) {
      var htmlClass = htmlClasses[j].toLowerCase();
      if (htmlClass === 'sh_sourcecode') {
        continue;
      }
      if (htmlClass.substr(0, 3) === 'sh_') {
        var language = htmlClass.substring(3);
        if (language in sh_languages) {
          sh_highlightElement(element, sh_languages[language]);
        }
        else if (typeof(prefix) === 'string' && typeof(suffix) === 'string') {
          sh_load(language, element, prefix, suffix);
        }
        else {
          throw 'Found <pre> element with class="' + htmlClass + '", but no such language exists';
        }
        break;
      }
    }
  }

}





