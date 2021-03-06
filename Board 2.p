/******************************************************************************
 * Copyright 2016 Specialized Solutions LLC
 *
 * Title to the Materials (contents of this file) remain with Specialized
 * Solutions LLC.  The Materials are copyrighted and are protected by United
 * States copyright laws.  Copyright notices cannot be removed from the
 * Materials.
 *
 * See the file titled "Specialized Solutions LLC License Agreement.txt"
 * that has been distributed with this file for further licensing details.
 *
 * Default Badge Script for DefCon 24
 *
 * This demo shows off many features of the PAWN language and the QCM
 * subsystem.
 *
 *****************************************************************************/

new mutation_mode = 0

new current_led_mode = 0	/*  0x00 == OFF
								0x10 == RED
								0x20 == GREEN
								0x30 == BLUE */
new saved_msg[QCM_CAN_MSG] = 0
/******************************************************************************
 * Menu handling code
 *****************************************************************************/
new const menu_items[4]{} = [ "None", "Drop", "Delay", "Mutate"]

show_menu()
{
	new i

    state menu

	qcm_display_bar(0,0,127,127,0)
	graphics_box(0,0,127,127,0xFFFF)

	for (i = 0; i < 4; i++)
	{
		if (i == mutation_mode)
		{
			qcm_display_bar(1,i * 20,126,i * 20 + 20, 0xFFFF)
			qcm_display_write_text(1,i * 20, 0x0000, LCD_FONT_MEDIUM,menu_items[i])
		}
		else
		{
			qcm_display_write_text(1,i * 20,0xFFFF,LCD_FONT_MEDIUM,menu_items[i])
		}
	}
}

input_switch_left_debounce() <menu>
{
	mutation_mode++;

	if (mutation_mode > 3)
	{
		mutation_mode = 0;
	}

	show_menu()
	printf("Changed %d\n", mutation_mode);
}

input_switch_right_debounce() <menu>
{
}

led_handler(rx_msg[QCM_CAN_MSG])
{
	new new_color = 0;

	if (rx_msg.data[0] == 0x00)
	{
		new_color = 0x0;
	}
	else if(rx_msg.data[0] == 0x10)
	{
		new_color = 0b1111100000000000
	}
	else if(rx_msg.data[0] == 0x20)
	{
		new_color = 0b0000011111100000
	}
	else if(rx_msg.data[0] == 0x30)
	{
		new_color = 0b0000000000011111
	}

   	qcm_led_set(LED_FRONT_BOTTOM, new_color)
   	qcm_led_set(LED_FRONT_TOP, new_color)
  	qcm_led_set(LED_REAR_BOTTOM, new_color)
  	qcm_led_set(LED_REAR_TOP, new_color)
}

start_demo()
{
}


@timer1() <menu>
{
}

@timer0() <menu>
{
	led_handler(saved_msg)
}

mutation_engine(rx_msg[QCM_CAN_MSG])
{
	if (mutation_mode == 0)			/* None */
	{
		led_handler(rx_msg)
	}
	else if (mutation_mode == 1)	/* Drop */
	{
	}
	else if (mutation_mode == 2)	/* Delay */
	{
		qcm_timer_start(TIMER_0,1000,false)
		saved_msg = rx_msg
	}
	else if (mutation_mode == 3)	/* Mutate */
	{
		new new_led = random(4) & 0x3
		printf("led = %d\n", new_led)
		rx_msg.data[0] = new_led * 0x10
		led_handler(rx_msg)
	}
}

stop_demo()
{
	qcm_timer_stop(TIMER_0)
	qcm_timer_stop(TIMER_1)
	qcm_led_set(LED_FRONT_BOTTOM, 0)
	qcm_led_set(LED_FRONT_TOP, 0)
	qcm_led_set(LED_REAR_BOTTOM, 0)
	qcm_led_set(LED_REAR_TOP, 0)
	mutation_mode = 0
}


/******************************************************************************
 * Default state handlers
 *****************************************************************************/

input_switch_right_debounce() <>
{

}

input_switch_left_debounce() <>
{

}

@timer1() <>
{

}


/******************************************************************************
 * Switch debounce routines
 *****************************************************************************/
@gpio_input_switch_right()
{
    /* start debounce timer */
    qcm_timer_start(TIMER_2,50,false)
}

@gpio_input_switch_left()
{
    /* start debounce timer */
    qcm_timer_start(TIMER_3,50,false)
}

@timer2()
{
    if (qcm_gpio_get_input(GPIO_INPUT_SWITCH_RIGHT))
    {
        /* button has been released - call new function to handle debounced input */
        input_switch_right_debounce()
    }
}

@timer3()
{
    if (qcm_gpio_get_input(GPIO_INPUT_SWITCH_LEFT))
    {
        /* button has been released - call new function to handle debounced input */
        input_switch_left_debounce()
    }
}


@can0_rx0(rx_msg[QCM_CAN_MSG])	/* Handler for all CAN 0 messages */
{
	new i;
	printf("CAN0 Msg Received: %x, %d, %d : ", rx_msg.id, rx_msg.is_extended, rx_msg.dlc)
   	mutation_engine(rx_msg)
}

/******************************************************************************
 * Main routine (initilization)
 *****************************************************************************/
main()
{
	sleep 1000

	state menu

	/* Initialize the Display */
	qcm_display_init()
	qcm_display_backlight(75)

	/* Initialize Switches */
	qcm_gpio_configure_handler(GPIO_INPUT_SWITCH_LEFT, GPIO_EVENT_HIGH)
	qcm_gpio_configure_handler(GPIO_INPUT_SWITCH_RIGHT, GPIO_EVENT_HIGH)

	/* Initialize CAN Interfaces */
	qcm_can_init(CAN0, 500000);
	qcm_can_configure_rx_handler(CAN0, CAN_RX_HANDLER_0, 0x100, false);

	show_menu()
	start_demo()
}

