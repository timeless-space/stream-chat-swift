//
//  WeatherHelper.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 10/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

enum WeatherCondition: String {
    case clearDay
    case clearNight

    case partlyCloudyDay
    case partlyCloudyNight

    case cloudyDay
    case cloudyNight

    case dustDay
    case dustNight

    case fogDay
    case fogNight

    // Rain
    case rainDay
    case rainNight

    /// A heavier version of rain (?)
    case showerDay
    case showerNight

    // Snow
    case snowDay
    case snowNight

    // Thunderstorm
    case thunderstormDay
    case thunderstormNight

    // Tornado
    case tornadoDay
    case tornadoNight
}

public class WeatherHelper {

    public static let shared = WeatherHelper()

    // Cold Messages
    var coldWeatherMessages = ["Colder than your dating streak",
                     "This air hurts my face"]
    // Hot Messages
    var hotWeatherMessages = ["Hot as hell",
                    "Hot as fcuk",
                    "Better shave your legs. It’s shorts weather",
                    "Sunblock. Sneakers. T-Shirt",
                    "Are we inside a fucking oven?"]
    // SunnyDay Messages
    var sunnyDayMessages = ["It’s going to be effing perfect",
                      "Sunblock. Sneakers. T-Shirt",
                      "Looking like a nice day, but I’ve been wrong before …",
                      "If ever there was a day to fight a bear, this would be the perfect day to do it",
                      "It’s bright, sun-shiny day!"]
    // Sunny night Messages
    var sunnyNightMessages = ["It’s going to be effing perfect"]
    // CloudyDay Messages
    var cloudyDayMessages = ["It’s cloudy. Like Snoop Dogg’s general existence",
                      "It’s meh, but it ain’t no double rainbow",
                      "It’s going to be effing perfect better"]
    // Cloudy night Messages
    var cloudyNightMessages = ["It’s cloudy. Like Snoop Dogg’s general existence"]
    // Snow Messages
    var snowMessages = ["Don’t eat the yellow snow"]
    // Windy Messages
    var windyMessages = ["Slow farts by mother naturE"]
    // Rainy day Messages
    var rainyDayMessages = ["There would never be rainbows without the rain …",
    "When life throws you a rainy day, play in the puddles",
    "Keep calm and dance in the rain",
    "Some people feel the rain. Others just get wet",
    "Rain is just confetti from the sky"]
    // Rainy night Messages
    var rainyNightMessages = ["Sleep is so much easier when it rains...",
    "Best thing one can do when it's raining is to let it rain",
    "I love falling asleep to the sound of rain",
    "Enjoy relaxing rain ASMR compliment of nature",
    "Rain is just confetti from the sky"]
    // Tornado Messages
    var tornadoMessages = ["Tornado! Take cover, Dorothy.",
    "Abandon all hope ye who venture out into this weather"]

    // Temperature Formatter
    var temperatureDisplayTextFormatter: NumberFormatter {
         let formatter = NumberFormatter()
         formatter.numberStyle = .decimal
         formatter.maximumFractionDigits = 0
         return formatter
     }

    var temperatureValueFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter = temperatureDisplayTextFormatter
        return formatter
    }

    public func getWeatherDetail(condition: String, tempInFahrenheit: Double = 0.0) -> WeatherDetailModel {
        var randomMessageArray: [String] = []
        if tempInFahrenheit < 60 {
            randomMessageArray.append(contentsOf: coldWeatherMessages)
        } else if tempInFahrenheit > 90 {
            randomMessageArray.append(contentsOf: hotWeatherMessages)
        }
        switch condition {
            // Sunny
        case WeatherCondition.clearDay.rawValue:
            randomMessageArray.append(contentsOf: sunnyDayMessages)
            return WeatherDetailModel(
                imageName: "partly_sunny_icon",
                backgroundImage: Appearance.default.images.weatherDay_bg,
                message: randomMessageArray.randomElement())
        case WeatherCondition.clearNight.rawValue:
            randomMessageArray.append(contentsOf: sunnyNightMessages)
            return WeatherDetailModel(
                imageName: "partly_cloudy_night_icon",
                backgroundImage: Appearance.default.images.weatherNight_bg,
                message: randomMessageArray.randomElement())
            // Fog
        case WeatherCondition.fogDay.rawValue:
            randomMessageArray.append(contentsOf: cloudyDayMessages)
            return WeatherDetailModel(
                imageName: "fog_icon",
                backgroundImage: Appearance.default.images.weatherDay_bg,
            message: randomMessageArray.randomElement())
        case WeatherCondition.fogNight.rawValue:
            randomMessageArray.append(contentsOf: cloudyNightMessages)
            return WeatherDetailModel(
                imageName: "fog_icon",
                backgroundImage: Appearance.default.images.weatherNight_bg,
                message: randomMessageArray.randomElement())
            // Cloudy
        case WeatherCondition.partlyCloudyDay.rawValue,
            WeatherCondition.cloudyDay.rawValue:
            randomMessageArray.append(contentsOf: cloudyDayMessages)
            return WeatherDetailModel(
                imageName: "partly_sunny_icon",
                backgroundImage: Appearance.default.images.weatherDay_bg,
                message: randomMessageArray.randomElement())
        case WeatherCondition.partlyCloudyNight.rawValue,
            WeatherCondition.cloudyNight.rawValue:
            randomMessageArray.append(contentsOf: cloudyNightMessages)
            return WeatherDetailModel(
                imageName: "partly_cloudy_night_icon",
                backgroundImage: Appearance.default.images.weatherNight_bg,
                message: randomMessageArray.randomElement()
            )
            // Rain
        case WeatherCondition.rainDay.rawValue,
            WeatherCondition.showerDay.rawValue:
            randomMessageArray.append(contentsOf: rainyDayMessages)
            return WeatherDetailModel(
                imageName: "rain_icon",
                backgroundImage: Appearance.default.images.weatherDay_bg,
                message: randomMessageArray.randomElement())
        case WeatherCondition.rainNight.rawValue,
            WeatherCondition.showerNight.rawValue:
            randomMessageArray.append(contentsOf: rainyNightMessages)
            return WeatherDetailModel(
                imageName: "rain_icon",
                backgroundImage: Appearance.default.images.weatherNight_bg,
                message: randomMessageArray.randomElement())
            // Snow
        case WeatherCondition.snowDay.rawValue:
            randomMessageArray.append(contentsOf: snowMessages)
            return WeatherDetailModel(
                imageName: "snow_icon",
                backgroundImage: Appearance.default.images.weatherDay_bg,
                message: randomMessageArray.randomElement())
        case WeatherCondition.snowNight.rawValue:
            randomMessageArray.append(contentsOf: snowMessages)
            return WeatherDetailModel(
                imageName: "snow_icon",
                backgroundImage: Appearance.default.images.weatherNight_bg,
                message: randomMessageArray.randomElement())
            // Thunderstorm
        case WeatherCondition.thunderstormDay.rawValue:
            randomMessageArray.append(contentsOf: rainyDayMessages)
            return WeatherDetailModel(
                imageName: "thunderstorm_icon",
                backgroundImage: Appearance.default.images.weatherDay_bg,
                message: randomMessageArray.randomElement())
        case WeatherCondition.thunderstormNight.rawValue:
            randomMessageArray.append(contentsOf: rainyNightMessages)
            return WeatherDetailModel(
                imageName: "thunderstorm_icon",
                backgroundImage: Appearance.default.images.weatherNight_bg,
                message: randomMessageArray.randomElement())
            // Tornado
        case WeatherCondition.tornadoDay.rawValue:
            randomMessageArray.append(contentsOf: tornadoMessages)
            return WeatherDetailModel(
                imageName: "tornado_icon",
                backgroundImage: Appearance.default.images.weatherDay_bg,
                message: randomMessageArray.randomElement())
        case WeatherCondition.tornadoNight.rawValue:
            randomMessageArray.append(contentsOf: tornadoMessages)
            return WeatherDetailModel(
                imageName: "tornado_icon",
                backgroundImage: Appearance.default.images.weatherNight_bg,
                message: randomMessageArray.randomElement())
            // Default
        default:
            return WeatherDetailModel(
                imageName: "rain_icon",
                backgroundImage: Appearance.default.images.weatherNight_bg,
                message: randomMessageArray.randomElement())
        }
    }
}
