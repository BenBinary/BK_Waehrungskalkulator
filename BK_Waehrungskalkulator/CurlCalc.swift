//
//  CurlCalc.swift
//  BK_Waehrungskalkulator
//
//  Created by Benedikt Kurz on 23.04.19.
//  Copyright © 2019 Benedikt Kurz. All rights reserved.
//

import Foundation


class CurlCalc {
    var lastUpdate: Date!
    var rates: [String:Double]!
    var currencies: [String]!
    
    
    init() {
        
        // aktuelle Kurse von der EZB laden
        if getEcbRates() {
            // saveRates()
        } else {
            // loadRates()
        }
        
        // sortierte Währungsliste anzeigen
        let keys = Array(rates.keys)
        currencies = keys.sorted(by: <)
        
    }
    
    
    private func getRatesFilename() -> String? {
        
        let fm = FileManager.default
        let urls = fm.urls(for: .cachesDirectory, in: .userDomainMask)
        
        if let url = urls.first {
            return url.appendingPathComponent("rates.plist").path
        }
        return nil
    }
    
    private func saveRates() {
        
        if rates.count <= 1 {
            return // nicht speichern, da der Datensatz nicht vollständig ist
        }
        
        if let ratespath = getRatesFilename() {
            let dict = NSMutableDictionary()
            dict.setObject(lastUpdate, forKey: "lastupdate" as NSCopying)
            dict.setObject(rates, forKey: "rates" as NSCopying)
            _ = dict.write(toFile: ratespath, atomically: true)
            
        }
    }
    
    private func loadRates() {
        
        if let ratespath = getRatesFilename() {
            
            if let dict = NSMutableDictionary(contentsOfFile: ratespath) {
                
                if let lu = dict.object(forKey: "lastUpdate") as? Date, let rt = dict.object(forKey: "rates") as? [String:Double] {
                    
                    lastUpdate = lu
                    rates = rt
                    return
                    
                }
                
            }
            
        }
        
        rates = ["EUR": 1.0]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd H:mm"
        lastUpdate = formatter.date(from: "1900-01-01 12:00")!
        
    }

    
    
    func getEcbRates() -> Bool {
        
        
        rates = ["EUR": 1.0]
        
        // Defaultdaten
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd H:mm"
        formatter.timeZone = TimeZone(abbreviation: "CET")
        lastUpdate = formatter.date(from: "1900-01-01 12:00")!
        
        // Kurse der EZB laden
        let ecburl = URL(string: "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml")!
        let content:String
        do {
            content = try String(contentsOf: ecburl)
        } catch {
            return false
        }
        
        
        // SWXMLHash-Objekt erzeugen
        let xml = SWXMLHash.parse(content)
        
        // Datum extrahieren
        let ecbtime = xml["gesmes:Envelope"]["Cube"]["Cube"].element?.attribute(by: "time")?.text ?? "1900-01-01"
        
        if ecbtime == "1990-01-01" {
            // Datum nicht gefunden --> fehlerhafte Daten
            return false
        }
        
        
        // Hinzufügen des 16:00 Uhr Elements für das Ganze
        lastUpdate = formatter.date(from: ecbtime + " 16:00")
        
        for r in xml["gesmes:Envelope"]["Cube"]["Cube"]["Cube"].all {
            
            if let currency = r.element?.attribute(by: "currency")?.text, let ratestr = r.element?.attribute(by: "rate")?.text {
                let rate = NSString(string: ratestr).doubleValue
                
                if rate != 0.0 {
                    rates[currency] = rate
                }
            }
        }
        
        return true
        
        
    }
    
}
