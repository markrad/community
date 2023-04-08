"""
Applet: Day Countdown
Summary: Number of days to event
Description: A simple display with an event name and the number of days before the provided date is reached.
Author: markrad
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_EVENT_NAME = "Unnamed Event"
CONFIG_EVENT_NAME = "day-countdown-event-name"
CONFIG_EVENT_DATE = "day-countdown-date"

def main(config):
    event_name = config.get(CONFIG_EVENT_NAME, DEFAULT_EVENT_NAME)
    now = time.now()
    now = time.time(year = now.year, month = now.month, day = now.day)
    work = config.get(CONFIG_EVENT_DATE)
    msg = "Date not set"
    if work != None:
        then = time.parse_time(work)
        then = time.time(year = then.year, month = then.month, day = then.day)
        diff = int((then - now).hours / 24)
        msg = "in {} days".format(diff)
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Box(width = 64, height = 1, color = "#FF2200"),
                render.Text(event_name),
                render.Text(msg, color = "#009900"),
                render.Box(width = 64, height = 1, color = "#FF2200"),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = CONFIG_EVENT_NAME,
                name = "Event name",
                desc = "A name for your event",
                icon = "user",
            ),
            schema.DateTime(
                id = CONFIG_EVENT_DATE,
                name = "Event Date",
                desc = "The date of the event. Time is ignored",
                icon = "gear",
            ),
        ],
    )
