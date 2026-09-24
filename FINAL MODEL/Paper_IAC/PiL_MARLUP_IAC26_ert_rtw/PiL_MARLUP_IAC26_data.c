/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: PiL_MARLUP_IAC26_data.c
 *
 * Code generated for Simulink model 'PiL_MARLUP_IAC26'.
 *
 * Model version                  : 4.24
 * Simulink Coder version         : 26.1 (R2026a) 20-Nov-2025
 * C/C++ source code generated on : Thu Sep 24 20:12:34 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: ARM Compatible->ARM Cortex-M
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "PiL_MARLUP_IAC26.h"

/* Constant parameters (default storage) */
const ConstP_PiL_MARLUP_IAC26_T PiL_MARLUP_IAC26_ConstP = {
  /* Expression: F_trim
   * Referenced by: '<Root>/F_trim'
   */
  { 285.75, 271.6, 256.1 },

  /* Pooled Parameter (Mixed Expressions)
   * Referenced by:
   *   '<Root>/References'
   *   '<Root>/Discrete State-Space Observer'
   */
  { 0.0, 0.0, 0.0, 0.0, 1.57163793025702, 0.0 },

  /* Expression: C_obs
   * Referenced by: '<Root>/Gain'
   */
  { 0.832616729676393, -1.5321010716126715, 0.00019726647200153029,
    0.0037845950332231451, -0.00061392518064956017, -0.0098875499470292613, 0.0,
    1.0, 0.0, 0.0, 0.0, 0.0, 0.00019726647200153026, 0.0037873234860773706,
    0.83284644128260854, -1.5277215969958877, 0.0037646587739887123,
    0.060316950244860813, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, -1.87012304471558E-5,
    -0.00031026987391938663, 0.00011467806421098354, 0.0018914705540516159,
    0.87813461303940787, -0.79160234951813369, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0 },

  /* Expression: L
   * Referenced by: '<Root>/Gain1'
   */
  { 0.16738327032360698, 1.5321010716126715, -0.00019726647200153029,
    -0.0037845950332231451, 0.00061392518064956017, 0.0098875499470292613,
    -0.00019726647200153026, -0.0037873234860773706, 0.16715355871739146,
    1.5277215969958877, -0.0037646587739887123, -0.060316950244860813,
    1.87012304471558E-5, 0.00031026987391938663, -0.00011467806421098354,
    -0.0018914705540516159, 0.12186538696059211, 0.79160234951813369 },

  /* Expression: K
   * Referenced by: '<Root>/LQR Controller'
   */
  { -2111.8098878073006, 4323.5502939227363, -2200.7429860093994,
    -718.941191501656, 1471.3526141549958, -748.86724749942732,
    -3736.9617836027978, 63.881117645094029, 3693.5232453731423,
    -1278.9995536365336, 22.526756548172735, 1264.8028547766887,
    1065.2364803761443, 1062.3251184723072, 1066.9500725529554,
    413.3656275888759, 413.08481526713621, 416.33168805375965 },

  /* Expression: K_I
   * Referenced by: '<S1>/K_I'
   */
  { -286.08365082326463, 582.21575952386809, -296.08000110481049,
    -505.62692636915619, 12.795810206919091, 504.50746505878521,
    134.97398555083737, 136.04300815823041, 139.08049074275522 }
};

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
