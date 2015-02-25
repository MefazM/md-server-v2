module AiGenerator
  class << self

    AI_PRESETS = {
      ai_easy:  {
        units:  {spearman:  10, crusader:  99999999},
        uid:  'ai',
        activity_period:  7.0,

        level:  -1,

        username:  "Wilford Dragan (easy)",

        heal:  [:circle_earth],
        buff:  [:arrow_air, :arrow_fire],
        debuff:  [:arrow_water, :z_earth],
        atk_spell:  [:rect_water, :z_fire]
      },
      ai_normal:  {
        units:  {spearman:  50, slinger:  15, scout:  10, crusader:  99999999},
        uid:  'ai',
        activity_period:  4.0,
        level:  0,

        username:  "Galkir Cantilever (normal)",

        heal:  [:arrow_earth, :circle_earth],
        buff:  [:arrow_air, :arrow_fire],
        debuff:  [:rect_water, :arrow_water, :z_fire ],
        atk_spell:  [:rect_air, :z_earth, :circle_water]
      },
      ai_hard:  {
        units:  {spearman:  250, adept:  20, slinger:  150, scout:  50, crusader:  99999999},
        uid:  'ai',
        activity_period:  2.0,

        level:  2,

        username:  "Krag Zarkanan (hard)",

        heal:  [:arrow_earth, :circle_earth],
        buff:  [:arrow_air, :arrow_fire],
        debuff:  [:rect_water, :arrow_water, :z_fire ],
        atk_spell:  [:rect_air, :z_earth, :circle_water, :z_air, :z_water, :circle_fire]
      }
    }

    def generate_all(player_level)
      AI_PRESETS.map {|uid, preset| {
        uid: uid, username: preset[:username], level: [preset[:level] + player_level, 0].max
      }}
    end

    def generate(type, player_level)
      AI_PRESETS[type.to_sym].tap{|preset| preset[:level] = [preset[:level] + player_level, 0].max}
    end
  end
end