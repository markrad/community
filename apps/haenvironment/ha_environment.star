"""
Applet: HA Temperatures 
Summary: Hass in and outdoor env
Description: Retrieves specific entities from Home Assistant to display the indoor and outdoor environment.
Author: markrad
"""
# Thanks to InTheDaylight14 for his app that show how to acquire value from HA with the REST interface
# Thanks to danmcclain for his code to layout the values which mine are startlingly similar to

load("cache.star", "cache")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

STATIC_ENDPOINT = "/api/states/"
DEFAULT_COLOR = "#aaaaaa"
CONFIG_URL = "ha_environment_nabu_casa_url"
CONFIG_TOKEN = "ha_environment_token"
CONFIG_OUTDOOR_TEMPERATURE = "ha_environment_out_temperature"
CONFIG_OUTDOOR_HUMIDITY = "ha_environment_out_humidity"
CONFIG_INDOOR_TEMPERATURE = "ha_environment_in_temperature"
CONFIG_INDOOR_HUMIDITY = "ha_environment_in_humidity"
CONFIG_PRESSURE = "ha_environment_pressure"
CONFIG_WEATHER = "ha_environment_weather"

def main(config):
    url = config.get(CONFIG_URL, None)
    token = config.get(CONFIG_TOKEN, None)
    od_temperature = "??"
    od_humidity = "??"
    id_temperature = "??"
    id_humidity = "??"
    pressure = "??"
    weather = "..."

    if not is_string_blank(url) and not is_string_blank(token):
        od_temperature = get_entity(url, token, config.get(CONFIG_OUTDOOR_TEMPERATURE, None))
        od_humidity = get_entity(url, token, config.get(CONFIG_OUTDOOR_HUMIDITY, None))
        id_temperature = get_entity(url, token, config.get(CONFIG_INDOOR_TEMPERATURE, None))
        id_humidity = get_entity(url, token, config.get(CONFIG_INDOOR_HUMIDITY, None))
        pressure = get_entity(url, token, config.get(CONFIG_PRESSURE, None))
        weather = get_weather(url, token, config.get(CONFIG_WEATHER))

    rows = [render.Box(height = 3)]
    rows.append(
        render.Box(
            height = 6,
            child = render.Row(
                children = [
                    render.Text("In  ", font = "tom-thumb"),
                    render.Text("{}".format(id_temperature) + "   ", font = "tom-thumb", color = "#33cc33"),
                    render.Text("{}".format(id_humidity), font = "tom-thumb", color = "#0040ff"),
                ],
            ),
        ),
    )
    rows.append(
        render.Box(
            height = 6,
            child = render.Row(
                children = [
                    render.Text("Out ", font = "tom-thumb"),
                    render.Text("{}".format(od_temperature) + "   ", font = "tom-thumb", color = "#33cc33"),
                    render.Text("{}".format(od_humidity), font = "tom-thumb", color = "#0040ff"),
                ],
            ),
        ),
    )
    rows.append(render.Box(height = 3))

    rows.append(render.Box(
        height = 6,
        child = render.Row(
            children = [
                render.Text("{}".format(pressure), font = "tom-thumb", color = "#930"),
            ],
        ),
    ))

    rows.append(
        render.Marquee(
            width = 64,
            offset_start = 64,
            offset_end = 64,
            child = render.Text(weather, font = "tom-thumb"),
        ),
    )

    return render.Root(
        child = render.Column(
            expanded = True,
            children = rows,
        ),
    )

def is_string_blank(string):
    return string == None or len(string) == 0

def get_entity(url, token, entity):
    result = "??"

    if not is_string_blank(entity):
        result = cache.get(entity)

        if result == None:
            body = call_ha(url, token, entity)

            if not "state" in body:
                result = "!BAD"
            else:
                result = body["state"]
                if "attributes" in body and "unit_of_measurement" in body["attributes"]:
                    result += body["attributes"]["unit_of_measurement"]
        else:
            print("Using cached state")
    else:
        print("Entity not provided")

    cache.set(entity, result, 60 * 5)
    return result

def get_weather(url, token, entity):
    result = "..."

    if not is_string_blank(entity):
        result = cache.get(entity)

        if result == None:
            body = call_ha(url, token, entity)
            if not "attributes" in body or not "forecast" in body["attributes"] or "list" != type(body["attributes"]["forecast"]):
                result = "JSON not recognized"
            else:
                forecast = (body["attributes"]["forecast"])[0]
                if not "templow" in forecast or not "temperature" in forecast or "float" != type(forecast["templow"]) or "float" != type(forecast["temperature"]):
                    result = "JSON does not contain forcast temps"
                else:
                    lo = int(math.round(forecast["templow"]))
                    hi = int(math.round(forecast["temperature"]))
                    unit = "  "
                    if "temperature_unit" in body["attributes"]:
                        unit = body["attributes"]["temperature_unit"]
                    result = "{} {}/{}{}".format(
                        (body["attributes"]["forecast"])[0]["condition"],
                        lo,
                        hi,
                        unit,
                    )
        else:
            print("Using cached state")
    else:
        print("Entity not provided")

    cache.set(entity, result, 60 * 120)
    return result

def call_ha(url, token, entity):
    full_token = "Bearer " + token
    full_url = url + STATIC_ENDPOINT + entity
    headers = {
        "Authorization": full_token,
        "content_type": "application/json",
    }
    res = http.get(
        url = full_url,
        headers = headers,
    )

    if res.status_code != 200:
        fail("HA Rest API request failed with status code: %d - %s" % (res.status_code, res.body()))

    return res.json()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = CONFIG_URL,
                name = "Nabu Casa Url",
                desc = "Your Nabu Casa URL for your Home Assistance instance",
                icon = "link",
            ),
            schema.Text(
                id = CONFIG_TOKEN,
                name = "Long-lived Token",
                desc = "Home Assistant long-lived access token",
                icon = "key",
            ),
            schema.Text(
                id = CONFIG_OUTDOOR_TEMPERATURE,
                name = "Outdoor Temperature",
                desc = "Home Assistant sensor entity with outdoor temperature",
                icon = "temperatureHalf",
            ),
            schema.Text(
                id = CONFIG_OUTDOOR_HUMIDITY,
                name = "Outdoor Humidity",
                desc = "Home Assistant sensor entity with the outdoor humidity",
                icon = "dropletPercent",
            ),
            schema.Text(
                id = CONFIG_INDOOR_TEMPERATURE,
                name = "Indoor Temperature",
                desc = "Home Assistant sensor entity with the indoor temperature",
                icon = "temperatureHalf",
            ),
            schema.Text(
                id = CONFIG_INDOOR_HUMIDITY,
                name = "Indoor Humidity",
                desc = "Home Assistant sensor entity with the indoor humidity",
                icon = "dropletPercent",
            ),
            schema.Text(
                id = CONFIG_PRESSURE,
                name = "Pressure",
                desc = "Home Assistant sensor entity containing the pressure",
                icon = "bars",
            ),
            schema.Text(
                id = CONFIG_WEATHER,
                name = "Weather",
                desc = "Home Assistant weather entity (displays first entry)",
                icon = "mountainSun",
            ),
        ],
    )
