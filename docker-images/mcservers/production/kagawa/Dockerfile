FROM ghcr.io/giganticminecraft/seichi_minecraft_server_base:sha-672ea19

ENV VERSION="1.16.5"

# DiscordSRV:
#   https://github.com/DiscordSRV/DiscordSRV/releases/download/v1.25.1/DiscordSRV-Build-1.25.1.jar
# LunaChat:
#   https://github.com/ucchyocean/LunaChat/releases/download/v3.0.16/LunaChat.jar
# MorningGlorySeeds:
#   https://github.com/SigureRuri/MorningGlorySeeds/releases/download/3.0/MorningGlorySeeds.jar
# ViaBackwards:
#   https://github.com/ViaVersion/ViaBackwards/releases/download/4.4.2/ViaBackwards-4.4.2.jar
# ViaVersion:
#   https://github.com/ViaVersion/ViaVersion/releases/download/4.4.2/ViaVersion-4.4.2.jar
# TimeToGo:
#   https://github.com/GiganticMinecraft/TimeToGo/releases/download/v2.0.0/TimeToGo-2.0.0.jar
ENV MODS="\
https://github.com/DiscordSRV/DiscordSRV/releases/download/v1.25.1/DiscordSRV-Build-1.25.1.jar\
https://github.com/ucchyocean/LunaChat/releases/download/v3.0.16/LunaChat.jar\
https://github.com/SigureRuri/MorningGlorySeeds/releases/download/3.0/MorningGlorySeeds.jar\
https://github.com/ViaVersion/ViaBackwards/releases/download/4.4.2/ViaBackwards-4.4.2.jar\
https://github.com/ViaVersion/ViaVersion/releases/download/4.4.2/ViaVersion-4.4.2.jar\
https://github.com/GiganticMinecraft/TimeToGo/releases/download/v2.1.0/TimeToGo-2.1.0.jar\
"

ENV CFG_REPLACEMENT__DISCORDSRV_GLOBAL_CHANNEL_ID="959300037844799560"
ENV CFG_REPLACEMENT__DISCORDSRV_CONSOLE_CHANNEL_ID="689841701333893163"

# プラグインの設定ファイル
COPY ./plugin-configs /plugins
