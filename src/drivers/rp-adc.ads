--
--  Copyright 2021 (C) Jeremy Grosser
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with RP.Clock;
with HAL;

package RP.ADC is
   subtype Analog_Value is HAL.UInt12;
   subtype ADC_Channel is Natural range 0 .. 4;

   --  We definitely don't have the resolution to measure microvolts, but
   --  keeping everything in these units allows us to do only integer
   --  arithmetic.
   type Microvolts is new Integer;

   --  The temperature sensor is not terribly accurate, so whole integer
   --  resolution is fine.
   type Celsius is new Integer;

   Temperature_Sensor : constant ADC_Channel := 4;

   procedure Enable;
   function Enabled return Boolean;

   procedure Configure
      (Channel : ADC_Channel)
   with Pre => RP.Clock.Frequency (RP.Clock.ADC) = 48_000_000;

   function Read
      (Channel : ADC_Channel)
      return Analog_Value;

   function Read_Microvolts
      (Channel : ADC_Channel;
       VREF    : Microvolts := 3_300_000)
       return Microvolts;

   --  Temperature constants from datasheet section 4.9.4
   --  May need calibration.
   function Temperature
      (Ref_Temp : Celsius := 27;
       Vbe      : Microvolts := 706_000;
       Slope    : Microvolts := 1_721)
      return Celsius;

end RP.ADC;
