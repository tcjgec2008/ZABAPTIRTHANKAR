METHOD get_text_str.

  IF iv_txt_key = '001'.
    rv_text = 'Check type &P1& is unknown.'(001).                "#EC NOTEXT
  ELSEIF iv_txt_key = '002'.
    rv_text = 'Check type &P1& is not supported for &P2&'(002).  "#EC NOTEXT
  ELSEIF iv_txt_key = '003'.                                "#EC NOTEXT
    rv_text = 'Simplification item catalog not found. Check SAPOSS connection or upload a version manually.'(003)."#EC NOTEXT
  ELSEIF iv_txt_key = '004'.
    rv_text = 'Applicable'(004).                                 "#EC NOTEXT
  ELSEIF iv_txt_key = '005'.
    rv_text = 'Not Applicable'(005).                             "#EC NOTEXT
  ELSEIF iv_txt_key = '006'.
    rv_text = 'Item is irrelevant. Source release does not match.'(006)."#EC NOTEXT
  ELSEIF iv_txt_key = '007'.
    rv_text = 'Item is irrelevant. Target release does not match.'(007)."#EC NOTEXT
  ELSEIF iv_txt_key = '008'.
    rv_text = 'Relevant'(008).                                   "#EC NOTEXT
  ELSEIF iv_txt_key = '009'.
    rv_text = 'Irrelevant'(009).                                 "#EC NOTEXT
  ELSEIF iv_txt_key = '010'.
    rv_text = 'Unknown'(010).                                    "#EC NOTEXT
  ELSEIF iv_txt_key = '011'.
    rv_text = 'Relevance cannot be determined. Please create an incident with component CA-TRS-TDBC and check the rule settings.'(011)."#EC NOTEXT
  ELSEIF iv_txt_key = '012'.
    rv_text = 'Relevance cannot be determined. Create an incident with component CA-TRS-TDBC and define a rule for the check.'(012)."#EC NOTEXT
  ELSEIF iv_txt_key = '013'.
    rv_text = 'Relevance cannot be determined. Please create an incident with component CA-TRS-TDBC and complete the rule settings.'(013)."#EC NOTEXT
  ELSEIF iv_txt_key = '014'.
    rv_text = 'Relevance cannot be determined. Please execute this check manually.'(014)."#EC NOTEXT
  ELSEIF iv_txt_key = '015'.
    rv_text = 'Function /SDF/SAPWL_T_UCOUNT_AGGREGATE does not exist in the system.  ST-PI installation must be updated.'(015)."#EC NOTEXT
  ELSEIF iv_txt_key = '016'.
    rv_text = 'Item is irrelevant. IDoc &P1& based check not passed.'(016)."#EC NOTEXT
  ELSEIF iv_txt_key = '017'.
    rv_text = 'IDoc based check not passed: &P1&.'(017).         "#EC NOTEXT
  ELSEIF iv_txt_key = '018'.
    rv_text = 'Item is irrelevant. &P1& based check not passed.'(018)."#EC NOTEXT
  ELSEIF iv_txt_key = '019'.
    rv_text = 'Item is irrelevant. DB table &P1& based check not passed.'(019)."#EC NOTEXT
  ELSEIF iv_txt_key = '020'.
    rv_text = 'Entry point check type &P1& is not supported: &P2&.'(020)."#EC NOTEXT
  ELSEIF iv_txt_key = '021'.
    rv_text = 'Item is irrelevant. The table &P1& has not been found.'(021)."#EC NOTEXT
  ELSEIF iv_txt_key = '022'.
    rv_text = 'The field &P1& is not found in table &P2&. Please check if add-ons are missing and switches are active.'(022)."#EC NOTEXT
  ELSEIF iv_txt_key = '023'.
    rv_text = 'Table &P1& based check could not be executed. Create an incident with component CA-TRS-TDBC and check the rule settings.'(023)."#EC NOTEXT
  ELSEIF iv_txt_key = '026'.
    rv_text = 'Business function check not supported: &P1&'(026)."#EC NOTEXT
  ELSEIF iv_txt_key = '027'.
    rv_text = 'The provided content file is invalid. Check the provided file.'(027)."#EC NOTEXT
  ELSEIF iv_txt_key = '028'.
    rv_text = 'The new content version cannot be overwritten with an old version.'(028)."#EC NOTEXT
  ELSEIF iv_txt_key = '029'.
    rv_text = 'Table &P1& based check has not been executed: &P2&'(029)."#EC NOTEXT
  ELSEIF iv_txt_key = '030'.
    rv_text = 'Relevance unknown: run check class'(030).         "#EC NOTEXT
  ELSEIF iv_txt_key = '031'.
    rv_text = 'Relevance unknown: execute check manually'(031).        "#EC NOTEXT
  ELSEIF iv_txt_key = '032'.
    rv_text = 'The action has been canceled by the user'(032).  "#EC NOTEXT
  ELSEIF iv_txt_key = '033'.
    CONCATENATE 'Table &P1& based check could not be executed: length of the value &P2& entered is longer than allowed &P3&.'(M01) "#EC NOTEXT
                'Create an incident with component CA-TRS-TDBC.'(M02) "#EC NOTEXT
                INTO rv_text SEPARATED BY space.
  ELSEIF iv_txt_key = '034'.
    rv_text = 'Target product version and stack cannot be read from stack.xml'(034)."#EC NOTEXT
  ELSEIF iv_txt_key = '035'.
    rv_text = 'Your check has been completed successfully. See the SUM log for the results of the check.'(035)."#EC NOTEXT
  ELSEIF iv_txt_key = '036'.
    rv_text = 'Minimum S/4HANA 1709 is supported. For target version &P1&, run the pre-checks according to SAP Note 2182725'(036)."#EC NOTEXT
  ELSEIF iv_txt_key = '037'.
    rv_text = 'Target version read from stack.xml: &P1&'(037).   "#EC NOTEXT
  ELSEIF iv_txt_key = '038'.
    rv_text = 'SUM log class &P1& instance cannot be created'(038)."#EC NOTEXT
  ELSEIF iv_txt_key = '039'.
    rv_text = 'SUM log error: &P1&'(039).                        "#EC NOTEXT
  ELSEIF iv_txt_key = '040'.
    rv_text = 'Relevance cannot be determined. Entry point &P1& based check not executed: not enough ST03N data (&P2& months)'(040)."#EC NOTEXT
  ELSEIF iv_txt_key = '041'.
    rv_text = 'Item is relevant. DB table &P1& based check passed'(041)."#EC NOTEXT
  ELSEIF iv_txt_key = '042'.
    rv_text = 'Item is relevant. &P1& based check passed'(042).  "#EC NOTEXT
  ELSEIF iv_txt_key = '043'.
    rv_text = 'Item is relevant. IDoc &P1& based check passed'(043)."#EC NOTEXT
  ELSEIF iv_txt_key = '044'.
    rv_text = 'No check has been executed before for the selected target SAP S/4HANA version.'(044)."#EC NOTEXT
  ELSEIF iv_txt_key = '045'.
    rv_text = 'Relevance: &P1&'(045).                            "#EC NOTEXT
  ELSEIF iv_txt_key = '046'.
    rv_text = '&P1&'.                                       "#EC NOTEXT
  ELSEIF iv_txt_key = '047'.
    rv_text = 'Relevance check overall information'(047).        "#EC NOTEXT
  ELSEIF iv_txt_key = '049'.                                "#EC NOTEXT
    rv_text = 'Simplification item catalog has been uploaded successfully.'(049)."#EC NOTEXT
  ELSEIF iv_txt_key = '050'.                                "#EC NOTEXT
    rv_text = 'SAP Readiness Check for SAP S/4HANA - Simplification Item Check'(050)."#EC NOTEXT
  ELSEIF iv_txt_key = '051'.                                "#EC NOTEXT
    rv_text = 'You have successfully changed the source of the simplification item catalog.'(051)."#EC NOTEXT
  ELSEIF iv_txt_key = '052'.                                "#EC NOTEXT
    rv_text = 'The file could not be opened. simplification item catalog has not been uploaded'(052). "#EC NOTEXT
  ELSEIF iv_txt_key = '053'.                                "#EC NOTEXT
    CONCATENATE 'Selected simplification item content was downloaded from SAP at &P1&.'(M03) "#EC NOTEXT
                'Remember to perform check again after you have uploaded simplification item content. Continue?'(M04) "#EC NOTEXT
                INTO rv_text SEPARATED BY space.
  ELSEIF iv_txt_key = '054'.                                "#EC NOTEXT
    CONCATENATE 'Selected simplification item catalog has been downloaded from SAP at &P1&,'(M05) "#EC NOTEXT
                'there is another local version that was downloaded from SAP at &P2&.'(M06) "#EC NOTEXT
                'Remember to perform check again after upload. Continue to overwrite?'(M07) "#EC NOTEXT
                INTO rv_text SEPARATED BY space.
  ELSEIF iv_txt_key = '055'.                                "#EC NOTEXT
    rv_text = 'Simplification item catalog can not be fetched from SAP through SAPOSS RfC connection. Action canceled.'(055)."#EC NOTEXT
  ELSEIF iv_txt_key = '056'.                                "#EC NOTEXT
    rv_text = 'Simplification item catalog has not been updated. A locally stored version will be used for the check.'(056)."#EC NOTEXT
  ELSEIF iv_txt_key = '057'.                                "#EC NOTEXT
    rv_text = 'Download simplification item catalog'(057).       "#EC NOTEXT
  ELSEIF iv_txt_key = '058'.                                "#EC NOTEXT
    rv_text = 'To be uploaded in other system'(058).             "#EC NOTEXT
  ELSEIF iv_txt_key = '059'.                                "#EC NOTEXT
    rv_text = 'Latest simplification item catalog can not be fetched from SAP. Check SAPOSS connection.'(059)."#EC NOTEXT
  ELSEIF iv_txt_key = '060'.                                "#EC NOTEXT
    rv_text = 'Task has been cancelled. Please upload a simplification item catalog version and execute the task again.'(060)."#EC NOTEXT
  ELSEIF iv_txt_key = '061'.                                "#EC NOTEXT
    rv_text = 'There is no locally stored simplification item catalog version available. Upload a version now?'(061)."#EC NOTEXT
  ELSEIF iv_txt_key = '062'.                                "#EC NOTEXT
    rv_text = 'The simplification item catalog has been successfully uploaded.'(062)."#EC NOTEXT
  ELSEIF iv_txt_key = '063'.                                "#EC NOTEXT
    rv_text = 'Switch simplification item catalog source to get the latest version from SAP. Continue?'(063)."#EC NOTEXT
  ELSEIF iv_txt_key = '064'.                                "#EC NOTEXT
    rv_text = 'Continue to use a local version of the simplification item catalog from SAP?'(064)."#EC NOTEXT
  ELSEIF iv_txt_key = '065'.                                "#EC NOTEXT
    rv_text = 'Simplification item catalog source switch to SAP by &P1& at &P2&'(065)."#EC NOTEXT
  ELSEIF iv_txt_key = '066'.                                "#EC NOTEXT
    rv_text = 'Simplification item catalog source switch to local by &P1& at &P2&'(066)."#EC NOTEXT
  ELSEIF iv_txt_key = '067'.
    rv_text = 'Item relevant; business function &P1& is active'(067)."#EC NOTEXT
  ELSEIF iv_txt_key = '068'.
    rv_text = 'Item relevant; business function &P1& is inactive'(068)."#EC NOTEXT
  ELSEIF iv_txt_key = '069'.
    rv_text = 'Item is irrelevant; business function &P1& is active'(069)."#EC NOTEXT
  ELSEIF iv_txt_key = '070'.
    rv_text = 'Item is irrelevant; business function &P1& is inactive'(070)."#EC NOTEXT
  ELSEIF iv_txt_key = '071'.                                "#EC NOTEXT
    rv_text = 'Simplification Item Catalog source: Fetched from SAP'(071)."#EC NOTEXT
  ELSEIF iv_txt_key = '072'.                                "#EC NOTEXT
    rv_text = 'Simplification Item Catalog source: Uploaded from file'(072)."#EC NOTEXT
  ELSEIF iv_txt_key = '073'.
    rv_text = 'Item is relevant. &P1&. Relevant criteria is ''&P2&'' and number found is &P3&.'(073)."#EC NOTEXT
  ELSEIF iv_txt_key = '074'.
    rv_text = 'Item is irrelevant. &P1&. Relevant criteria is ''&P2&'' and number found is &P3&.'(074)."#EC NOTEXT
  ELSEIF iv_txt_key = '075'.                                "#EC NOTEXT
    rv_text = 'SAP Readiness Check for SAP S/4HANA - Switch Test Mode'(075). "#EC NOTEXT
  ELSEIF iv_txt_key = '076'.                                "#EC NOTEXT
    CONCATENATE 'You choose to download the simplification item catalog which is stored locally;'(M08)
                'the current version was downloaded from SAP at &P1&.'(M09) "#EC NOTEXT
                'It can be used by uploading to other systems. Continue?'(M10) "#EC NOTEXT
                INTO rv_text SEPARATED BY space.
  ELSEIF iv_txt_key = '077'.                                "#EC NOTEXT
    CONCATENATE 'You choose to download the simplification item catalog fetched from SAP;'(M11)
                'the current version was downloaded from SAP at &P1&.'(M09) "#EC NOTEXT
                'It can be used by uploading to other systems. Continue?'(M10) "#EC NOTEXT
                INTO rv_text SEPARATED BY space.
  ELSEIF iv_txt_key = '078'.                                "#EC NOTEXT
    rv_text = 'SAP BW/4HANA simplification item catalog not found. Check SAPOSS connection or upload a new version manually.'(078)."#EC NOTEXT
  ELSEIF iv_txt_key = '079'.                                "#EC NOTEXT
    rv_text = 'Manually uploaded ST03N data downloaded from &P1& at &P2& is used for relevance check.'(079)."#EC NOTEXT
  ELSEIF iv_txt_key = '080'.
    rv_text = 'Relevance check performed in system &P1& by user &P2&.'(080)."#EC NOTEXT
  ELSEIF iv_txt_key = '081'.
    rv_text = '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'."#EC NOTEXT

  ELSEIF iv_txt_key = '082'.                                "#EC NOTEXT
    rv_text = 'Simplification item content downloaded from SAP by &P1& at &P2&.'(082)."#EC NOTEXT
  ELSEIF iv_txt_key = '083'.                                "#EC NOTEXT
    rv_text = 'Simplification item content downloaded successfully from SAP.'(083)."#EC NOTEXT
  ELSEIF iv_txt_key = '084'.                                "#EC NOTEXT
    rv_text = 'Simplification item content uploaded from file by &P1& at &P2&.'(084)."#EC NOTEXT
  ELSEIF iv_txt_key = '085'.                                "#EC NOTEXT
    rv_text = 'Simplification item content downloaded from SAP with test mode by &P1& at &P2&.'(085)."#EC NOTEXT

    "For consistency check
  ELSEIF iv_txt_key = '100'.
    rv_text = 'Check started at &P1&'(100).                      "#EC NOTEXT
  ELSEIF iv_txt_key = '101'.
    rv_text = 'Check ended at &P1&'(101).                        "#EC NOTEXT
  ELSEIF iv_txt_key = '102'.
    rv_text = 'Check total run time is &P1& seconds'(102).       "#EC NOTEXT
  ELSEIF iv_txt_key = '103'.
    rv_text = '&P1& not found; check the implementation status of SAP Note &P2&.'(103)."#EC NOTEXT
  ELSEIF iv_txt_key = '104'.
    rv_text = 'Consistency check overall information'(104).      "#EC NOTEXT
  ELSEIF iv_txt_key = '105'.
    rv_text = 'Consistency check running time: &P1& seconds'(105)."#EC NOTEXT
  ELSEIF iv_txt_key = '106'.
    rv_text = '&P1& items checked for consistency'(106).         "#EC NOTEXT
  ELSEIF iv_txt_key = '107'.
    rv_text = '&P1& items have been checked for consistency'(107)."#EC NOTEXT   "This is better than 106
  ELSEIF iv_txt_key = '108'.
    rv_text = 'Check class: &P1&'(108).                          "#EC NOTEXT
  ELSEIF iv_txt_key = '109'.
    rv_text = 'Method &P1& of class &P2& does not exist. Check if latest version of SAP Note &P3& has been implemented.'(109)."#EC NOTEXT
  ELSEIF iv_txt_key = '110'.
    rv_text = 'Dynamic call of class &P1& method &P2& failed: &P3&.'(110)."#EC NOTEXT
  ELSEIF iv_txt_key = '111'.
    rv_text = 'Check item "&P1&"'(111).      "#EC NOTEXT
  ELSEIF iv_txt_key = '112'.
    rv_text = 'Provide SAP S/4HANA conversion target to run simplification item relevance check.'(112)."#EC NOTEXT
  ELSEIF iv_txt_key = '113'.
    rv_text = 'Check class might be out-of-date. Implement latest version of SAP Note &P1&. Implemented version:&P2&.'(113)."#EC NOTEXT
  ELSEIF iv_txt_key = '114'.
    rv_text = 'Relevance cannot be determined automatically because method &P1& of class &P2& does not exist.'(114)."#EC NOTEXT
  ELSEIF iv_txt_key = '115'.
    rv_text = 'Inconsistency warning found with &P1&.'(115).      "#EC NOTEXT
  ELSEIF iv_txt_key = '116'.
    rv_text = 'Inconsistency error found with &P1&.'(116).        "#EC NOTEXT
  ELSEIF iv_txt_key = '117'.
    CONCATENATE 'The chosen target product version &P1& is not supported. Please use SAP S/4HANA 1709 or a higher version.'(M12) "#EC NOTEXT
                'Do you want to continue?'(M13) "#EC NOTEXT
                INTO rv_text SEPARATED BY space.
  ELSEIF iv_txt_key = '118'.
    rv_text = '&P1& items have been skipped for consistency check in total.'(118)."#EC NOTEXT
  ELSEIF iv_txt_key = '119'.
    rv_text = '&P1& items have been skipped for consistency check because they are irrelevant.'(119)."#EC NOTEXT
  ELSEIF iv_txt_key = '120'.
    rv_text = '&P1& items have been skipped for consistency check because manual check is needed.'(120)."#EC NOTEXT
  ELSEIF iv_txt_key = '121'.
    rv_text = '&P1& items have been skipped for consistency check because check class has not been defined.'(121)."#EC NOTEXT
  ELSEIF iv_txt_key = '122'.
    rv_text = 'Skip-able consistency error found, exemption can be applied to the item in simplification item list.'(122)."#EC NOTEXT
  ELSEIF iv_txt_key = '123'.
    rv_text = 'Consistency error found, exemption has been applied by &P1& before at &P2&.'(123)."#EC NOTEXT
  ELSEIF iv_txt_key = '124'.
    CONCATENATE 'By applying the exemption to &P1& you confirm that you have read and understood the messages from the check results.'(M14) "#EC NOTEXT
                'Do you want to apply the exemption to all sub-checks with a skipable error (RC=7)?'(M15)"#EC NOTEXT
                INTO rv_text SEPARATED BY space.
  ELSEIF iv_txt_key = '125'.
    CONCATENATE 'You are about to undo the exemption for &P1&.'(M16) "#EC NOTEXT
                'The item will turn red again and block the conversion process until being exempted again.'(M17) "#EC NOTEXT
                'Read the consistency check (RC=7) result for this item for more information.'(M18) "#EC NOTEXT
                'Do you want to continue?'(M13) "#EC NOTEXT
                INTO rv_text SEPARATED BY space.
  ELSEIF iv_txt_key = '126'.
    rv_text = 'Exemption applied to &P1& by &P2& at &P3&. &P4&.'(126)."#EC NOTEXT
  ELSEIF iv_txt_key = '127'.
    rv_text = 'Exemption revoked from &P1& by &P2& at &P3&. &P4&.'(127)."#EC NOTEXT
  ELSEIF iv_txt_key = '128'.
    rv_text = 'Latest simplification item catalog could not be fetched. Check SAPOSS RFC connection in SM59.'(128)."#EC NOTEXT
  ELSEIF iv_txt_key = '129'.
    rv_text = 'Check Sub-ID:"&P1&", return code = &P2&.'(129).    "#EC NOTEXT
  ELSEIF iv_txt_key = '130'.
    rv_text = 'Consistency check result...'(130).                "#EC NOTEXT
  ELSEIF iv_txt_key = '131'.
    rv_text = 'Consistency check performed in system &P1&'(131)."#EC NOTEXT
  ELSEIF iv_txt_key = '132'. "->used as tooltip; should not exceed 40 characters
    rv_text = 'No potential inconsistency'(132).                 "#EC NOTEXT
  ELSEIF iv_txt_key = '133'. "->used as tooltip; should not exceed 40 characters
    rv_text = 'Inconsistency at level warning'(133).             "#EC NOTEXT
  ELSEIF iv_txt_key = '134'. "->used as tooltip; should not exceed 40 characters
    rv_text = 'Inconsistency at level error'(134).               "#EC NOTEXT
  ELSEIF iv_txt_key = '135'. "->used as tooltip; should not exceed 40 characters
    rv_text = 'Inconsistency at level abortion'(135).            "#EC NOTEXT
  ELSEIF iv_txt_key = '136'. "->used as tooltip; should not exceed 40 characters
    rv_text = 'Not Applicable'(136).                             "#EC NOTEXT
  ELSEIF iv_txt_key = '137'. "->used as tooltip; should not exceed 40 characters
    rv_text = 'Inconsistency exempted'(137).                     "#EC NOTEXT
  ELSEIF iv_txt_key = '138'. "->used as tooltip; should not exceed 40 characters
    rv_text = 'Inconsistency can be exempted'(138). "#EC NOTEXT
  ELSEIF iv_txt_key = '139'.
    rv_text = 'The simplification item catalog version used for the check was downloaded from SAP at &P1&'(139)."#EC NOTEXT
  ELSEIF iv_txt_key = '140'.
    rv_text = 'Highest consistency check return code: &P1&'(140)."#EC NOTEXT
  ELSEIF iv_txt_key = '141'.
    rv_text = 'Target version: &P1& [&P2&]'(141).                "#EC NOTEXT
  ELSEIF iv_txt_key = '142'.
    rv_text = 'Check...'(142).                                   "#EC NOTEXT
  ELSEIF iv_txt_key = '143'.
    rv_text = 'No consistency check result returned from check class &P1&.'(143)."#EC NOTEXT
  ELSEIF iv_txt_key = '144'.
    rv_text = 'Check execution has stopped because target SUM log folder &P1& could not be found.'(144)."#EC NOTEXT
  ELSEIF iv_txt_key = '145'.
    rv_text = 'Check execution has stopped because prerequisites of consistency check in SUM mode have not been met.'(145)."#EC NOTEXT
  ELSEIF iv_txt_key = '146'.
    rv_text = 'SAP Note &P1& is out-of-date, latest version must be implement first.'(146)."#EC NOTEXT
  ELSEIF iv_txt_key = '147'.
    rv_text = 'Check return code = &P1&'(147).                   "#EC NOTEXT
  ELSEIF iv_txt_key = '148'.
    rv_text = 'Software Update Manager(SUM) mode: &P1&.'(148).    "#EC NOTEXT
  ELSEIF iv_txt_key = '149'.
    rv_text = 'Check performed in background mode (sy-batch): &P1&.'(149)."#EC NOTEXT
  ELSEIF iv_txt_key = '150'.
    rv_text = 'Software Update Manager(SUM) phase: first phase.'(150)."#EC NOTEXT
  ELSEIF iv_txt_key = '151'.
    rv_text = 'Software Update Manager(SUM) phase: second phase.'(151)."#EC NOTEXT
  ELSEIF iv_txt_key = '152'.
    rv_text = 'Software Update Manager(SUM) phase: unknown.'(152)."#EC NOTEXT
  ELSEIF iv_txt_key = '153'.
    rv_text = '&P1& error can be skipped and has been converted automatically into a warning in SUM first phase.'(153)."#EC NOTEXT
  ELSEIF iv_txt_key = '154'.
    rv_text = 'Consistency error found. To skip the error, create an exemption for it after other errors have been resolved.'(154)."#EC NOTEXT
  ELSEIF iv_txt_key = '155'.
    rv_text = 'Software Update Manager(SUM) log file: &P1&.'(155)."#EC NOTEXT
  ELSEIF iv_txt_key = '156'.
    rv_text = 'Consistency check has been overwritten by custom exit.'(156)."#EC NOTEXT
  ELSEIF iv_txt_key = '157'.
    rv_text = '&P1& simplification item to be checked.'(157).     "#EC NOTEXT
  ELSEIF iv_txt_key = '158'.
    rv_text = 'All simplification items to be checked.'(158).      "#EC NOTEXT
  ELSEIF iv_txt_key = '159'.
    rv_text = 'Number of check result returned: &P1&.'(159).     "#EC NOTEXT
  ELSEIF iv_txt_key = '160'.
    rv_text = 'Error occurs when calling check class &P1&. Please check details in transaction ST22.'(160)."#EC NOTEXT
  ELSEIF iv_txt_key = '161'.
    rv_text = '&P1& check texts are returned for &P2&. Only the first &P3& are kept to reduce resource consumption.'(161)."#EC NOTEXT
  ELSEIF iv_txt_key = '162'.
    rv_text = 'The operation impossible for &P1& that has no skip-able consistency check result.'(162)."#EC NOTEXT
  ELSEIF iv_txt_key = '163'.
    rv_text = 'The operation is only possible after other severer consistency errors are resolved and recheck is performed for &P1&.'(163)."#EC NOTEXT
  ELSEIF iv_txt_key = '164'.
    rv_text = 'Target product version cannot be read from Simplification item catalog.'(164)."#EC NOTEXT
  ELSEIF iv_txt_key = '165'.
    rv_text = 'The target release &P1& is no longer supported for a system conversion.'(165)."#EC NOTEXT
  ELSEIF iv_txt_key = '166'.
    rv_text = 'Please see the release information note &P1&. Please choose at least &P2&.'(166)."#EC NOTEXT
  ELSEIF iv_txt_key = '167'.
    rv_text = 'The minimum upgrade target release with this report is &P1&.'(167)."#EC NOTEXT
  ELSEIF iv_txt_key = '168'.
    rv_text = 'Please see SAP Note &P1& for the upgrade to &P2&.'(168)."#EC NOTEXT
  ELSEIF iv_txt_key = '169'.
    rv_text = 'Simplification item catalog can not be fetched from SAP through SAP-SUPPORT_PORTAL HTTP connection. Action canceled.'(169)."#EC NOTEXT
  ELSEIF iv_txt_key = '170'.
    rv_text = 'Simplification item catalog not found. Check SAP-SUPPORT_PORTAL connection or upload a version manually.'(170)."#EC NOTEXT
  ELSEIF iv_txt_key = '171'.
    rv_text = 'SAP BW/4HANA simplification item catalog not found. Check SAP-SUPPORT_PORTAL connection or upload a new version manually.'(171)."#EC NOTEXT
  ELSEIF iv_txt_key = '172'.
    rv_text = 'Latest simplification item catalog could not be fetched. Check SAP-SUPPORT_PORTAL HTTP connection in SM59.'(172)."#EC NOTEXT
  ELSEIF iv_txt_key = '173'.
    rv_text = 'Consistency check performed in system &P1&'(173)."#EC NOTEXT
  ELSEIF iv_txt_key = '174'.
    rv_text = 'Simplification item catalog can not be fetched from SAP through Download Service. Action canceled.'(174)."#EC NOTEXT
  ELSEIF iv_txt_key = '175'.
    rv_text = 'Simplification item catalog not found. Check Download Service connection or upload a version manually.'(175)."#EC NOTEXT
  ELSEIF iv_txt_key = '176'.
    rv_text = 'BW/4HANA simplification item catalog not found. Check Download Service connection or upload a new version manually.'(176)."#EC NOTEXT
  ELSEIF iv_txt_key = '177'.
    rv_text = 'Latest simplificatin items not fetched; check Download Service connection.'(177)."#EC NOTEXT

    "For application log and texts
  ELSEIF iv_txt_key = 'A00'.
    rv_text = 'SAP S/4HANA simplification item check'(A00).      "#EC NOTEXT
  ELSEIF iv_txt_key = 'A01'.
    rv_text = 'Consistency check'(A01).                          "#EC NOTEXT
  ELSEIF iv_txt_key = 'A02'.
    rv_text = 'Consistency check for selected items'(A02).       "#EC NOTEXT
  ELSEIF iv_txt_key = 'A03'.
    rv_text = 'Consistency check result'(A03).                   "#EC NOTEXT
  ELSEIF iv_txt_key = 'A04'.
    rv_text = 'There are no results available for the consistency check.'(A04).   "#EC NOTEXT
  ELSEIF iv_txt_key = 'A05'.
    rv_text = 'Item consistency check exemption'(A05).           "#EC NOTEXT
  ELSEIF iv_txt_key = 'A06'.
    rv_text = 'There is no log available for consistency check exemptions.'(A06)."#EC NOTEXT
  ELSEIF iv_txt_key = 'A07'.
    rv_text = 'Log of exemptions of consistenchy check errors that can be skipped.'(A07)."#EC NOTEXT
  ELSEIF iv_txt_key = 'A08'.
    rv_text = 'Item relevance check'(A08).                       "#EC NOTEXT
  ELSEIF iv_txt_key = 'A09'.
    rv_text = 'There is no application log available.'(A09).            "#EC NOTEXT
  ELSEIF iv_txt_key = 'A10'.
    rv_text = 'Simplification item check application log'(A10).   "#EC NOTEXT
  ELSEIF iv_txt_key = 'A11'.
    rv_text = 'Simplification item catalog source change log'(A11)."#EC NOTEXT
  ELSEIF iv_txt_key = 'A12'.
    rv_text = 'Consistency check log'(A12).                      "#EC NOTEXT

    "For note status check
  ELSEIF iv_txt_key = 'B00'.
    rv_text = 'SAP Note &P1& has not been downloaded.'(B00).     "#EC NOTEXT
  ELSEIF iv_txt_key = 'B01'.
    rv_text = 'Latest version &P1& of SAP Note &P2& is implemented.'(B01)."#EC NOTEXT "Latest version (&P1&) of necessary SAP Note &P2& has been implemented.
  ELSEIF iv_txt_key = 'B02'.
    rv_text = 'The implemented version of SAP Note &P1& is outdated.'(B02)."#EC NOTEXT
  ELSEIF iv_txt_key = 'B03'.
    rv_text = 'Download of latest version of SAP Note &P1& available. Please implement the note.'(B03)."#EC NOTEXT
  ELSEIF iv_txt_key = 'B04'.
    rv_text = 'An outdated version of SAP Note &P1& has been downloaded but not implemented.'(B04)."#EC NOTEXT
  ELSEIF iv_txt_key = 'B05'.
    rv_text = 'Latest version of necessary SAP Note &P1& has not been implemented. Do you want to continue?'(B05)."#EC NOTEXT
  ELSEIF iv_txt_key = 'B06'.
    rv_text = 'SAP Note &P1& has been implemented. We could not determine whether the SAP Note is up-to-date.'(B06)."#EC NOTEXT
  ELSEIF iv_txt_key = 'B07'.
    rv_text = 'SAP Note &P1& has not been implemented. We could not determine whether it is up-to-date.'(B07)."#EC NOTEXT
  ELSEIF iv_txt_key = 'B08'.
    rv_text = 'Implemented version &P2& of SAP Note &P1& is out-of-date.'(B08)."#EC NOTEXT
  ELSEIF iv_txt_key = 'B09'.
    rv_text = 'Implementation status of SAP Note &P1& is unknown.'(B09)."#EC NOTEXT
  ELSEIF iv_txt_key = 'B10'.
    rv_text = 'Required SAP Note &P1& not implemented'(B10).     "#EC NOTEXT
  ELSEIF iv_txt_key = 'B11'.
    rv_text = 'Required version of SAP Note &P1& is &P2&. Implemented version is &P3&.'(B11)."#EC NOTEXT
  ELSEIF iv_txt_key = 'B12'.
    rv_text = 'Minimum required version &P1& of SAP Note &P2& not implemented.'(B12)."#EC NOTEXT
  ELSEIF iv_txt_key = 'B13'.
    rv_text = 'Action not allowed. Required version of SAP Note &P1& is &P2& but implemented version is &P3&.'(B13)."#EC NOTEXT
  ELSEIF iv_txt_key = 'B14'.
    rv_text = 'Note that this system has been configured for testing purposes only.'(B14)."#EC NOTEXT
  ELSEIF iv_txt_key = 'B15'.
    rv_text = 'Buffered relevance data less than 30 days( &P1& ) is used.'(B15)."#EC NOTEXT
  ELSEIF iv_txt_key = 'B16'.
    rv_text = 'Buffered consistency data less than 30 days( &P1& ) is used.'(B16)."#EC NOTEXT
  ELSEIF iv_txt_key = 'B17'.
    rv_text = 'Implemented version &P2& of SAP Note &P1& is not up to date.'(B17)."#EC NOTEXT

    "For Simplification Item relevance
  ELSEIF iv_txt_key = 'C00'. "Yes
    rv_text = 'Check performed, item is probably relevant. Check business impact note.'(C00)."#EC NOTEXT
  ELSEIF iv_txt_key = 'C10'. "Yes ->used as tooltip; should not exceed 40 characters
    rv_text = 'Probably relevant'(C10).                          "#EC NOTEXT

  ELSEIF iv_txt_key = 'C01'. "No
    rv_text = 'Check performed, item irrelevant.'(C01).          "#EC NOTEXT
  ELSEIF iv_txt_key = 'C11'. "No ->used as tooltip; should not exceed 40 characters
    rv_text = 'Irrelevant'(C11).                                 "#EC NOTEXT

  ELSEIF iv_txt_key = 'C02'. "manual_check or rule_issue
    rv_text = 'Relevance cannot be automatically determined. Check business impact note.'(C02)."#EC NOTEXT
  ELSEIF iv_txt_key = 'C12'. "Unknown ->used as tooltip; should not exceed 40 characters
    rv_text = 'Relevance unknown'(C12).                          "#EC NOTEXT

  ELSEIF iv_txt_key = 'C03'. "miss_ch_clas
    rv_text = 'Relevance cannot be determined automatically. Please update and implement SAP Note &P1&.'(C03)."#EC NOTEXT
*  ELSEIF iv_txt_key = 'C13'. "Unknown ->used as tooltip; should not exceed 40 characters
*    rv_text = 'Relevance Unknown'.                          "#EC NOTEXT

  ELSEIF iv_txt_key = 'C04'.
    rv_text = 'Relevance not determied by check class &P1& or simple check. Please implement SAP Note &P2&.'(C04)."#EC NOTEXT

  ELSEIF iv_txt_key = 'C05'. "miss_usg_data
    rv_text = 'To determine relevance automatically, there need to be at least 10 sets of usage data in transaction ST03N.'(C05)."#EC NOTEXT

  ELSEIF iv_txt_key = 'C08'.
    rv_text = 'Relevant as checked by &P1&: &P2&.'(C08).         "#EC NOTEXT
  ELSEIF iv_txt_key = 'C09'.
    rv_text = 'Irrelevant as checked by &P1&: &P2&.'(C09).       "#EC NOTEXT

  ELSEIF iv_txt_key = 'C13'. "miss_ch_clas
    rv_text = '( Containing SAP Note &P1& out-of-date. Current implemented version: &P2&)'(C13)."#EC NOTEXT

  ENDIF.

  IF rv_text CA '&'.
    IF iv_para1 IS SUPPLIED.
      REPLACE ALL OCCURRENCES OF '&P1&' IN rv_text WITH iv_para1.
      IF iv_para2 IS SUPPLIED.
        REPLACE ALL OCCURRENCES OF '&P2&' IN rv_text WITH iv_para2.
        IF iv_para3 IS SUPPLIED.
          REPLACE ALL OCCURRENCES OF '&P3&' IN rv_text WITH iv_para3.
          IF iv_para4 IS SUPPLIED.
            REPLACE ALL OCCURRENCES OF '&P4&' IN rv_text WITH iv_para4.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

ENDMETHOD.