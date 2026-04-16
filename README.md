# Tela de Configurações - Jornada do Conhecimento

Arquivos incluídos:

- `ui/settings/SettingsOverlay.tscn`
- `ui/settings/SettingsOverlay.gd`
- `scripts/SettingsManager.gd`

## Como instalar

1. Copie a pasta `ui/settings` para o seu projeto Godot 4.
2. Copie `scripts/SettingsManager.gd` para o projeto.
3. Vá em **Project > Project Settings > Autoload**.
4. Adicione `res://scripts/SettingsManager.gd` com o nome `SettingsManager`.
5. Confirme se no **Audio Bus Layout** existem os buses:
   - `Master`
   - `SFX`
   - `Music`
6. Garanta que a ação `ui_cancel` está mapeada para `Esc`.

## Como abrir o menu

Por botão:

```gdscript
func _on_settings_button_pressed() -> void:
    SettingsManager.open_menu()
```

Por teclado:

- O `SettingsManager` já abre/fecha com `ui_cancel` (`Esc`).

## Observações

- O overlay é global e pode abrir em qualquer cena.
- O salvamento é feito em `user://settings.cfg`.
- O menu já possui:
  - fade in / fade out
  - hover com escala nos botões
  - sliders de volume geral e SFX
  - toggles de música, VFX e legendas
  - resetar configurações
  - fechar por botão, clique fora ou `Esc`

## Ajuste visual rápido

Se quiser aproximar ainda mais da referência:

- troque os textos `VOL` e `SFX` por ícones próprios em `Label` ou `TextureRect`
- substitua os `HSlider` por uma skin personalizada com `Theme`
- use uma fonte display arredondada no título
