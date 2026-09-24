/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: PiL_MARLUP_IAC26.c
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
#include "rtwtypes.h"

/* Block states (default storage) */
DW_PiL_MARLUP_IAC26_T PiL_MARLUP_IAC26_DW;

/* External inputs (root inport signals with default storage) */
ExtU_PiL_MARLUP_IAC26_T PiL_MARLUP_IAC26_U;

/* External outputs (root outports fed by signals with default storage) */
ExtY_PiL_MARLUP_IAC26_T PiL_MARLUP_IAC26_Y;

/* Real-time model */
static RT_MODEL_PiL_MARLUP_IAC26_T PiL_MARLUP_IAC26_M_;
RT_MODEL_PiL_MARLUP_IAC26_T *const PiL_MARLUP_IAC26_M = &PiL_MARLUP_IAC26_M_;

/* Model step function */
void PiL_MARLUP_IAC26_step(void)
{
  real_T rtb_Gain1[6];
  real_T tmp[6];
  real_T tmp_0[6];
  real_T rtb_Sum2[3];
  real_T tmp_1[3];
  real_T rtb_Sum2_0;
  real_T tmp_2;
  real_T tmp_3;
  real_T u0;
  int32_T i;
  int32_T i_0;

  /* DiscreteStateSpace: '<Root>/Discrete State-Space Observer' */
  {
    rtb_Gain1[0] = 1.0*PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[0];
    rtb_Gain1[1] = 1.0*PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[1];
    rtb_Gain1[2] = 1.0*PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[2];
    rtb_Gain1[3] = 1.0*PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[3];
    rtb_Gain1[4] = 1.0*PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[4];
    rtb_Gain1[5] = 1.0*PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[5];
  }

  /* Gain: '<Root>/Gain' */
  for (i = 0; i < 6; i++) {
    tmp[i] = 0.0;
  }

  for (i = 0; i < 6; i++) {
    rtb_Sum2_0 = rtb_Gain1[i];
    for (i_0 = 0; i_0 < 6; i_0++) {
      tmp[i_0] += PiL_MARLUP_IAC26_ConstP.Gain_Gain[6 * i + i_0] * rtb_Sum2_0;
    }

    /* Gain: '<Root>/Gain1' */
    tmp_0[i] = 0.0;
  }

  /* End of Gain: '<Root>/Gain' */

  /* Gain: '<Root>/Gain1' incorporates:
   *  Inport: '<Root>/In1'
   */
  for (i = 0; i < 3; i++) {
    rtb_Sum2_0 = PiL_MARLUP_IAC26_U.Output[i];
    for (i_0 = 0; i_0 < 6; i_0++) {
      tmp_0[i_0] += PiL_MARLUP_IAC26_ConstP.Gain1_Gain[6 * i + i_0] * rtb_Sum2_0;
    }
  }

  /* Sum: '<Root>/Sum' incorporates:
   *  Constant: '<Root>/References'
   *  Sum: '<Root>/Sum3'
   */
  for (i = 0; i < 6; i++) {
    rtb_Gain1[i] = PiL_MARLUP_IAC26_ConstP.pooled1[i] - (tmp[i] + tmp_0[i]);
  }

  /* End of Sum: '<Root>/Sum' */

  /* Gain: '<S1>/K_I' */
  rtb_Sum2_0 = 0.0;
  tmp_2 = 0.0;
  tmp_3 = 0.0;
  for (i = 0; i < 3; i++) {
    /* Sum: '<Root>/Sum1' incorporates:
     *  Constant: '<Root>/F_trim'
     *  Gain: '<Root>/LQR Controller'
     */
    u0 = 0.0;
    for (i_0 = 0; i_0 < 6; i_0++) {
      u0 += PiL_MARLUP_IAC26_ConstP.LQRController_Gain[3 * i_0 + i] *
        rtb_Gain1[i_0];
    }

    tmp_1[i] = u0 + PiL_MARLUP_IAC26_ConstP.F_trim_Value[i];

    /* Gain: '<S1>/K_I' incorporates:
     *  DiscreteIntegrator: '<S1>/Integrator_I'
     */
    u0 = PiL_MARLUP_IAC26_DW.Integrator_I_DSTATE[i];
    rtb_Sum2_0 += PiL_MARLUP_IAC26_ConstP.K_I_Gain[3 * i] * u0;
    tmp_2 += PiL_MARLUP_IAC26_ConstP.K_I_Gain[3 * i + 1] * u0;
    tmp_3 += PiL_MARLUP_IAC26_ConstP.K_I_Gain[3 * i + 2] * u0;
  }

  /* Saturate: '<Root>/Saturation' incorporates:
   *  Gain: '<S1>/K_I'
   *  Sum: '<Root>/Sum1'
   */
  u0 = tmp_1[0] + rtb_Sum2_0;
  if (u0 > 1000.0) {
    u0 = 1000.0;
  } else if (u0 < -1000.0) {
    u0 = -1000.0;
  }

  /* RateLimiter: '<Root>/Rate Limiter' */
  rtb_Sum2_0 = u0 - PiL_MARLUP_IAC26_DW.PrevY[0];
  if (rtb_Sum2_0 > 1000.0) {
    u0 = PiL_MARLUP_IAC26_DW.PrevY[0] + 1000.0;
  } else if (rtb_Sum2_0 < -1000.0) {
    u0 = PiL_MARLUP_IAC26_DW.PrevY[0] - 1000.0;
  }

  PiL_MARLUP_IAC26_Y.Out1[0] = u0;
  PiL_MARLUP_IAC26_DW.PrevY[0] = u0;

  /* Sum: '<Root>/Sum2' incorporates:
   *  Constant: '<Root>/F_trim'
   */
  rtb_Sum2[0] = u0 - 285.75;

  /* Saturate: '<Root>/Saturation' incorporates:
   *  Gain: '<S1>/K_I'
   *  Sum: '<Root>/Sum1'
   */
  u0 = tmp_1[1] + tmp_2;
  if (u0 > 1000.0) {
    u0 = 1000.0;
  } else if (u0 < -1000.0) {
    u0 = -1000.0;
  }

  /* RateLimiter: '<Root>/Rate Limiter' */
  rtb_Sum2_0 = u0 - PiL_MARLUP_IAC26_DW.PrevY[1];
  if (rtb_Sum2_0 > 1000.0) {
    u0 = PiL_MARLUP_IAC26_DW.PrevY[1] + 1000.0;
  } else if (rtb_Sum2_0 < -1000.0) {
    u0 = PiL_MARLUP_IAC26_DW.PrevY[1] - 1000.0;
  }

  PiL_MARLUP_IAC26_Y.Out1[1] = u0;
  PiL_MARLUP_IAC26_DW.PrevY[1] = u0;

  /* Sum: '<Root>/Sum2' incorporates:
   *  Constant: '<Root>/F_trim'
   */
  rtb_Sum2[1] = u0 - 271.6;

  /* Saturate: '<Root>/Saturation' incorporates:
   *  Gain: '<S1>/K_I'
   *  Sum: '<Root>/Sum1'
   */
  u0 = tmp_1[2] + tmp_3;
  if (u0 > 1000.0) {
    u0 = 1000.0;
  } else if (u0 < -1000.0) {
    u0 = -1000.0;
  }

  /* RateLimiter: '<Root>/Rate Limiter' */
  rtb_Sum2_0 = u0 - PiL_MARLUP_IAC26_DW.PrevY[2];
  if (rtb_Sum2_0 > 1000.0) {
    u0 = PiL_MARLUP_IAC26_DW.PrevY[2] + 1000.0;
  } else if (rtb_Sum2_0 < -1000.0) {
    u0 = PiL_MARLUP_IAC26_DW.PrevY[2] - 1000.0;
  }

  PiL_MARLUP_IAC26_Y.Out1[2] = u0;
  PiL_MARLUP_IAC26_DW.PrevY[2] = u0;

  /* Sum: '<Root>/Sum2' incorporates:
   *  Constant: '<Root>/F_trim'
   */
  rtb_Sum2[2] = u0 - 256.1;

  /* Update for DiscreteStateSpace: '<Root>/Discrete State-Space Observer' incorporates:
   *  Inport: '<Root>/In1'
   */
  {
    real_T xnew[6];
    xnew[0] = 0.81758660571157282*
      PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[0] +
      0.01000117170785144*PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[1]
      + 0.00023521348772609168*
      PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[2]
      + (-2.1810866599604718E-5)*
      PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[4];
    xnew[0] += (-1.3860434375681509E-7)*rtb_Sum2[0] + 2.8696953584211242E-7*
      rtb_Sum2[1]
      + (-1.461902967528575E-7)*rtb_Sum2[2]
      + 0.18276491488095131*PiL_MARLUP_IAC26_U.Output[0]
      + (-0.00023521348772609168)*PiL_MARLUP_IAC26_U.Output[1]
      + 2.1810866599604718E-5*PiL_MARLUP_IAC26_U.Output[2];
    xnew[1] = (-1.4740998222404986)*
      PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[0] +
      1.0003515205925242*PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[1]
      + 0.0038025242661598635*
      PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[2]
      + (-0.00031169379071376539)*
      PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[4];
    xnew[1] += (-2.7722492713230042E-5)*rtb_Sum2[0] + 5.7397269455422838E-5*
      rtb_Sum2[1]
      + (-2.9239772193479744E-5)*rtb_Sum2[2]
      + 1.5444080593466942*PiL_MARLUP_IAC26_U.Output[0]
      + (-0.0038025242661598635)*PiL_MARLUP_IAC26_U.Output[1]
      + 0.00031169379071376539*PiL_MARLUP_IAC26_U.Output[2];
    xnew[2] = 0.00023518378608853555*
      PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[0] +
      0.81785067767254527*PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[2]
      + 0.010001133371867289*
      PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[3]
      + 0.00013363390624235934*
      PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[4];
    xnew[2] += (-2.5138504517723789E-7)*rtb_Sum2[0] + 3.6165613450084972E-10*
      rtb_Sum2[1]
      + 2.4360886624753025E-7*rtb_Sum2[2]
      + (-0.00023518378608853555)*PiL_MARLUP_IAC26_U.Output[0]
      + 0.18248934159455824*PiL_MARLUP_IAC26_U.Output[1]
      + (-0.00013363390624235934)*PiL_MARLUP_IAC26_U.Output[2];
    xnew[3] = 0.0037992975088673633*
      PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[0] +
      (-1.47160107507828)*PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[2]
      + 1.0003400192671035*PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[3]
      + 0.0018999126826651632*
      PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[4];
    xnew[3] += (-5.0279858033671109E-5)*rtb_Sum2[0] + 7.2335325623242323E-8*
      rtb_Sum2[1]
      + 4.87245341187005E-5*rtb_Sum2[2]
      + (-0.0037992975088673633)*PiL_MARLUP_IAC26_U.Output[0]
      + 1.5396087820069777*PiL_MARLUP_IAC26_U.Output[1]
      + (-0.0018999126826651632)*PiL_MARLUP_IAC26_U.Output[2];
    xnew[4] = (-0.00071280068011985278)*
      PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[0] +
      0.0043678282764373208*PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA
      [2]
      + 0.87021858954422648*PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA
      [4]
      + 0.010000000000000002*
      PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[5];
    xnew[4] += 6.167858245297002E-7*rtb_Sum2[0] + 6.0956439499655011E-7*
      rtb_Sum2[1]
      + 6.0269405595875013E-7*rtb_Sum2[2]
      + 0.00071280068011985278*PiL_MARLUP_IAC26_U.Output[0]
      + (-0.0043678282764373208)*PiL_MARLUP_IAC26_U.Output[1]
      + 0.12978141045577346*PiL_MARLUP_IAC26_U.Output[2];
    xnew[5] = (-0.0098875499470292613)*
      PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[0] +
      0.060316950244860813*PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[2]
      + (-0.79160234951813369)*
      PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[4]
      + 1.0*PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[5];
    xnew[5] += 0.00012335716490594002*rtb_Sum2[0] + 0.00012191287899931*
      rtb_Sum2[1]
      + 0.00012053881119175*rtb_Sum2[2]
      + 0.0098875499470292613*PiL_MARLUP_IAC26_U.Output[0]
      + (-0.060316950244860813)*PiL_MARLUP_IAC26_U.Output[1]
      + 0.79160234951813369*PiL_MARLUP_IAC26_U.Output[2];
    (void) memcpy(PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA, xnew,
                  sizeof(real_T)*6);
  }

  /* Update for DiscreteIntegrator: '<S1>/Integrator_I' incorporates:
   *  Constant: '<S1>/y_ref'
   *  Inport: '<Root>/In1'
   *  Sum: '<S1>/Sum_I'
   */
  PiL_MARLUP_IAC26_DW.Integrator_I_DSTATE[0] += (0.0 -
    PiL_MARLUP_IAC26_U.Output[0]) * 0.01;
  PiL_MARLUP_IAC26_DW.Integrator_I_DSTATE[1] += (0.0 -
    PiL_MARLUP_IAC26_U.Output[1]) * 0.01;
  PiL_MARLUP_IAC26_DW.Integrator_I_DSTATE[2] += (1.57163793025702 -
    PiL_MARLUP_IAC26_U.Output[2]) * 0.01;
}

/* Model initialize function */
void PiL_MARLUP_IAC26_initialize(void)
{
  {
    int32_T i;

    /* InitializeConditions for DiscreteStateSpace: '<Root>/Discrete State-Space Observer' */
    for (i = 0; i < 6; i++) {
      PiL_MARLUP_IAC26_DW.DiscreteStateSpaceObserver_DSTA[i] =
        PiL_MARLUP_IAC26_ConstP.pooled1[i];
    }
  }
}

/* Model terminate function */
void PiL_MARLUP_IAC26_terminate(void)
{
  /* (no terminate code required) */
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
