/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: PiL_MARLUP_IAC26.h
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

#ifndef PiL_MARLUP_IAC26_h_
#define PiL_MARLUP_IAC26_h_
#ifndef PiL_MARLUP_IAC26_COMMON_INCLUDES_
#define PiL_MARLUP_IAC26_COMMON_INCLUDES_
#include "rtwtypes.h"
#include "math.h"
#endif                                 /* PiL_MARLUP_IAC26_COMMON_INCLUDES_ */

#include "PiL_MARLUP_IAC26_types.h"
#include <string.h>
#include <stddef.h>
#include "MW_target_hardware_resources.h"

/* Macros for accessing real-time model data structure */
#ifndef rtmGetErrorStatus
#define rtmGetErrorStatus(rtm)         ((rtm)->errorStatus)
#endif

#ifndef rtmSetErrorStatus
#define rtmSetErrorStatus(rtm, val)    ((rtm)->errorStatus = (val))
#endif

/* Block states (default storage) for system '<Root>' */
typedef struct {
  real_T DiscreteStateSpaceObserver_DSTA[6];
                                    /* '<Root>/Discrete State-Space Observer' */
  real_T Integrator_I_DSTATE[3];       /* '<S1>/Integrator_I' */
  real_T PrevY[3];                     /* '<Root>/Rate Limiter' */
} DW_PiL_MARLUP_IAC26_T;

/* Constant parameters (default storage) */
typedef struct {
  /* Expression: F_trim
   * Referenced by: '<Root>/F_trim'
   */
  real_T F_trim_Value[3];

  /* Pooled Parameter (Mixed Expressions)
   * Referenced by:
   *   '<Root>/References'
   *   '<Root>/Discrete State-Space Observer'
   */
  real_T pooled1[6];

  /* Expression: C_obs
   * Referenced by: '<Root>/Gain'
   */
  real_T Gain_Gain[36];

  /* Expression: L
   * Referenced by: '<Root>/Gain1'
   */
  real_T Gain1_Gain[18];

  /* Expression: K
   * Referenced by: '<Root>/LQR Controller'
   */
  real_T LQRController_Gain[18];

  /* Expression: K_I
   * Referenced by: '<S1>/K_I'
   */
  real_T K_I_Gain[9];
} ConstP_PiL_MARLUP_IAC26_T;

/* External inputs (root inport signals with default storage) */
typedef struct {
  real_T Output[3];                    /* '<Root>/In1' */
} ExtU_PiL_MARLUP_IAC26_T;

/* External outputs (root outports fed by signals with default storage) */
typedef struct {
  real_T Out1[3];                      /* '<Root>/Out1' */
} ExtY_PiL_MARLUP_IAC26_T;

/* Real-time Model Data Structure */
struct tag_RTM_PiL_MARLUP_IAC26_T {
  const char_T * volatile errorStatus;
};

/* Block states (default storage) */
extern DW_PiL_MARLUP_IAC26_T PiL_MARLUP_IAC26_DW;

/* External inputs (root inport signals with default storage) */
extern ExtU_PiL_MARLUP_IAC26_T PiL_MARLUP_IAC26_U;

/* External outputs (root outports fed by signals with default storage) */
extern ExtY_PiL_MARLUP_IAC26_T PiL_MARLUP_IAC26_Y;

/* Constant parameters (default storage) */
extern const ConstP_PiL_MARLUP_IAC26_T PiL_MARLUP_IAC26_ConstP;

/* Model entry point functions */
extern void PiL_MARLUP_IAC26_initialize(void);
extern void PiL_MARLUP_IAC26_step(void);
extern void PiL_MARLUP_IAC26_terminate(void);

/* Real-time Model object */
extern RT_MODEL_PiL_MARLUP_IAC26_T *const PiL_MARLUP_IAC26_M;
extern volatile boolean_T stopRequested;
extern volatile boolean_T runModel;

/*-
 * The generated code includes comments that allow you to trace directly
 * back to the appropriate location in the model.  The basic format
 * is <system>/block_name, where system is the system number (uniquely
 * assigned by Simulink) and block_name is the name of the block.
 *
 * Use the MATLAB hilite_system command to trace the generated code back
 * to the model.  For example,
 *
 * hilite_system('<S3>')    - opens system 3
 * hilite_system('<S3>/Kp') - opens and selects block Kp which resides in S3
 *
 * Here is the system hierarchy for this model
 *
 * '<Root>' : 'PiL_MARLUP_IAC26'
 * '<S1>'   : 'PiL_MARLUP_IAC26/Integral Action'
 */
#endif                                 /* PiL_MARLUP_IAC26_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
