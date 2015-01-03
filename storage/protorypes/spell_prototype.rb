

class SpellPrototype
  def initialize(spell_data)
    # Convert ms to seconds
    @uid = spell_data[:uid].to_sym
    @time = spell_data[:time] || 0
    @area = spell_data[:area]
    @vertical_area = spell_data[:vertical_area]
    @mana_cost = spell_data[:mana_cost]
    @description = spell_data[:description]
    @name = spell_data[:name]
    @spellbook_timing = spell_data[:spellbook_timing]

    client_description_left = []
    client_description_right = []

    spell_data[:client_description].split('|').each do |row|
      row_data = row.split '='
      client_description_left << row_data.first
      client_description_right << row_data.last
    end

    spell_prototype[:client_description] = {
      right: client_description_right.join("\n"),
      left: client_description_left.join("\n")
    }

  end

end