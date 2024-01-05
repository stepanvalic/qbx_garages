local Translations = {
    error = {
        no_vehicles = "Na tomto místě momentálně nemáte žádná vozidla...",
        not_impound = "Vaše vozidlo není v areálu",
        not_owned = "Toto vozidlo nelze uložit",
        not_correct_type = "Tento typ vozidla zde nelze uložit",
        not_enough = "Není dostatek peněz",
        no_garage = "Žádné",
        vehicle_occupied = "Toto vozidlo nelze uložit, protože není prázdné",
    },
    success = {
        vehicle_parked = "Vozidlo je uloženo",
    },
    menu = {
        header = {
            house_car = "Domácí garáž %{hodnota}",
            public_car = "Veřejná garáž %{hodnota}",
            public_sea = "Veřejná loděnice %{hodnota}",
            public_air = "Veřejný hangár %{hodnota}",
            job_car = "Pracovní garáž %{hodnota}",
            job_sea = "Job Boathouse %{value}",
            job_air = "Pracovní hangár %{hodnota}",
            gang_car = "Gang Garage %{value}",
            gang_sea = "Gang Boathouse %{value}",
            gang_air = "Hangár gangu %{hodnota}",
            depot_car = "Depot %{hodnota}",
            depot_sea = "Depot %{hodnota}",
            depot_air = "Depo %{hodnota}",
            vehicles = "Dostupná vozidla",
            depot = "%{hodnota} [ $%{hodnota2} ]",
            garage = "%{value} [ %{value2} ]",
        },
        leave = {
            car = "⬅ Leave Garage",
            moře = "⬅ Opustit loděnici",
            air = "⬅ Leave Hangar",
        },
        text = {
            vehicles = "Zobrazit uložená vozidla!",
            depot = "Deska: %{hodnota}<br>Palivo: %{hodnota2} | Motor: %{hodnota3} | Karoserie: %{hodnota4}",
            garage = "Stav: %{hodnota}<br>Palivo: %{hodnota2} | Motor: %{hodnota3} | Karoserie: %{hodnota4}",
        }
    },
    status = {
        out = "Out",
        garaged = "Garaged",
        impound = "Zabaveno policií",
    },
    info = {
        car_e = "E - Garáž",
        sea_e = "E - Loděnice",
        air_e = "E - Hangár",
        park_e = "E - Sklad vozidel",
        house_garage = "Domácí garáž",
    }
}

if GetConvar('qb_locale', 'en') == 'cs' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
--translate by stepan_valic
