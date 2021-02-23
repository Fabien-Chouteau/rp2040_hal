with RP2040_SVD.Interrupts; use RP2040_SVD.Interrupts;
with RP2040_SVD.RESETS;     use RP2040_SVD.RESETS;
with RP2040_SVD.TIMER;      use RP2040_SVD.TIMER;
with Cortex_M_SVD.NVIC;     use Cortex_M_SVD.NVIC;
with System.Machine_Code;

package body RP.Timer is
   procedure Reset is
   begin
      RESETS_Periph.RESET.timer := False;
      while not RESETS_Periph.RESET_DONE.timer loop
         null;
      end loop;

      TIMER_Periph.TIMELW := 0;
      TIMER_Periph.TIMEHW := 0;
   end Reset;

   function Clock
      return Time
   is
      Next_High : UInt32;
      High      : UInt32;
      Low       : UInt32;
   begin
      High := TIMER_Periph.TIMERAWH;
      loop
         --  If TIMEHW changed while we were reading TIMELW, try again
         Low := TIMER_Periph.TIMERAWL;
         Next_High := TIMER_Periph.TIMERAWH;
         exit when Next_High = High;
         High := Next_High;
      end loop;
      return Time (Shift_Left (UInt64 (High), 32) or UInt64 (Low));
   end Clock;

   procedure TIMER_IRQ_2_Handler is
   begin
      TIMER_Periph.INTR.ALARM_2 := True;
   end TIMER_IRQ_2_Handler;

   procedure Enable
      (This : in out Delays)
   is
   begin
      TIMER_Periph.INTE.ALARM_2 := True;
      NVIC_Periph.NVIC_ICPR := Shift_Left (1, TIMER_IRQ_2_Interrupt);
      NVIC_Periph.NVIC_ISER := Shift_Left (1, TIMER_IRQ_2_Interrupt);
   end Enable;

   procedure Disable
      (This : in out Delays)
   is
   begin
      TIMER_Periph.INTE.ALARM_2 := False;
   end Disable;

   function Enabled
      (This : Delays)
      return Boolean
   is (TIMER_Periph.INTE.ALARM_2);

   overriding
   procedure Delay_Microseconds
      (This : in out Delays;
       Us   : Integer)
   is
      T : constant UInt32 := UInt32 (Integer (TIMER_Periph.TIMERAWL) + Us);
   begin
      TIMER_Periph.ALARM2 := T;
      loop
         System.Machine_Code.Asm ("wfi", Volatile => True);
         exit when TIMER_Periph.INTS.ALARM_2 or TIMER_Periph.TIMERAWL >= T;
      end loop;
   end Delay_Microseconds;

   overriding
   procedure Delay_Milliseconds
      (This : in out Delays;
       Ms   : Integer)
   is
   begin
      for I in 1 .. Ms loop
         Delay_Microseconds (This, 1_000);
      end loop;
   end Delay_Milliseconds;

   overriding
   procedure Delay_Seconds
      (This : in out Delays;
       S    : Integer)
   is
   begin
      for I in 1 .. S loop
         Delay_Microseconds (This, 1_000_000);
      end loop;
   end Delay_Seconds;
end RP.Timer;