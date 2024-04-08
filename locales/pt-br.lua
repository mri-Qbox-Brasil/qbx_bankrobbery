local Translations = {
    success = {
        success_message = "Sucesso",
        fuses_are_blown = "Os fusíveis foram queimados",
        door_has_opened = "A porta foi aberta"
    },
    error = {
        cancel_message = "Cancelado",
        safe_too_strong = "Parece que o cofre é muito forte...",
        missing_item = "Você está sem um item...",
        bank_already_open = "O banco já está aberto...",
        minimum_police_required = "Mínimo de %{police} policiais necessários",
        security_lock_active = "O bloqueio de segurança está ativo, abrir a porta atualmente não é possível",
        wrong_type = "%{receiver} não recebeu o tipo certo para o argumento '%{argumento}'\ntipo recebido: %{receivedType}\nvalor recebido: %{receivedValue}\ntipo esperado: %{expected}",
        fuses_already_blown = "Os fusíveis já estão queimados...",
        event_trigger_wrong = "%{evento}%{extraInfo} foi acionado quando algumas condições não foram atendidas, fonte: %{source}",
        missing_ignition_source = "Você está sem uma fonte de ignição"
    },
    general = {
        breaking_open_safe = "Arrombando o cofre...",
        connecting_hacking_device = "Conectando o dispositivo de hacking...",
        fleeca_robbery_alert = "Tentativa de roubo ao banco Fleeca",
        paleto_robbery_alert = "Tentativa de roubo ao banco Blain County Savings",
        pacific_robbery_alert = "Tentativa de roubo ao banco Pacific Standard",
        break_safe_open_option_target = "Arrombar Cofre",
        break_safe_open_option_drawtext = "[E] Arrombar o cofre",
        validating_bankcard = "Validando cartão...",
        thermite_detonating_in_seconds = "Termita vai detonar em %{time} segundo(s)",
        bank_robbery_police_call = "10-90: Roubo a banco"
    }
}

if GetConvar('qb_locale', 'en') == 'pt-br' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
