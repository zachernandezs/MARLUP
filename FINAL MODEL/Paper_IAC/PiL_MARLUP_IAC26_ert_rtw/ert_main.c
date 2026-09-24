/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: ert_main.c
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
#include "MW_target_hardware_resources.h"

volatile int IsrOverrun = 0;
static boolean_T OverrunFlag = 0;
void rt_OneStep(void)
{
  /* Check for overrun. Protect OverrunFlag against preemption */
  if (OverrunFlag++) {
    IsrOverrun = 1;
    OverrunFlag--;
    return;
  }

  __enable_irq();
  PiL_MARLUP_IAC26_step();

  /* Get model outputs here */
  __disable_irq();
  OverrunFlag--;
}

volatile boolean_T stopRequested;
volatile boolean_T runModel;
int main(int argc, char **argv)
{
  float modelBaseRate = 0.01;
  float systemClock = 84.0;

  /* Initialize variables */
  stopRequested = false;
  runModel = false;

#if !defined(MW_FREERTOS) && defined(MW_MULTI_TASKING_MODE) && (MW_MULTI_TASKING_MODE == 1)

  MW_ASM (" SVC #1");

#endif

  ;

  // Start Peripheral initialization imported from STM32CubeMX project;
  void MX_DMA_Init(void);
  void MX_GPIO_Init(void);
  void MX_USART2_UART_Init(void);
  HAL_Init();
  SystemClock_Config();
  PeriphCommonClock_Config();
  MX_DMA_Init();
  MX_GPIO_Init();
  MX_USART2_UART_Init();

  // End Peripheral initialization imported from STM32CubeMX project;
  rtmSetErrorStatus(PiL_MARLUP_IAC26_M, 0);
  PiL_MARLUP_IAC26_initialize();
  __disable_irq();
  ARMCM_SysTick_Config(modelBaseRate);
  runModel =
    rtmGetErrorStatus(PiL_MARLUP_IAC26_M) == (NULL);
  __enable_irq();
  __enable_irq();
  while (runModel) {
    stopRequested = !(
                      rtmGetErrorStatus(PiL_MARLUP_IAC26_M) == (NULL));
  }

  /* Terminate model */
  PiL_MARLUP_IAC26_terminate();

#if !defined(MW_FREERTOS) && !defined(USE_RTX)

  (void) systemClock;

#endif

  ;
  __disable_irq();
  return 0;
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
