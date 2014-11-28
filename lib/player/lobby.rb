require 'thread_safe'

module Lobby

  INVITE_LIVE_TIME = 10

  module Inviteable
    def register_in_lobby
      Lobby.register(player_rate, uid)
    end

    def lobby_info
      [uid, @username, @score.current_level]
    end

    def invite_to_battle(opponent_uid)
      Lobby.invite(uid, opponent_uid)
    end

    def create_ai_battle(ai_uid)

    end
  end

  class << self

    AI_PRESETS = {
      :ai_easy => {
        :units => {:spearman => 10, :crusader => 99999999},
        :activity_period => 9.0,

        :level => -1,
        :name => "Wilford Dragan (easy)",

        :heal => [:circle_earth],
        :buff => [:arrow_air, :arrow_fire],
        :debuff => [:arrow_water, :z_earth],
        :atk_spell => [:rect_water, :z_fire]
      },
      :ai_normal => {
        :units => {:spearman => 50, :slinger => 15, :scout => 10, :crusader => 99999999},
        :activity_period => 6.0,
        :level => 0,
        :name => "Galkir Cantilever (normal)",

        :heal => [:arrow_earth, :circle_earth],
        :buff => [:arrow_air, :arrow_fire],
        :debuff => [:rect_water, :arrow_water, :z_fire ],
        :atk_spell => [:rect_air, :z_earth, :circle_water]
      },
      :ai_hard => {
        :units => {:spearman => 250, :adept => 20, :slinger => 150, :scout => 50, :crusader => 99999999},
        :activity_period => 3.0,

        :level => 2,
        :name => "Krag Zarkanan (hard)",

        :heal => [:arrow_earth, :circle_earth],
        :buff => [:arrow_air, :arrow_fire],
        :debuff => [:rect_water, :arrow_water, :z_fire ],
        :atk_spell => [:rect_air, :z_earth, :circle_water, :z_air, :z_water, :circle_fire]
      }
    }

    def register(rate, player_id)
      Storage.redis_pool.with {|conn| conn.ZADD('lobby:players_rate', rate, player_id)}
    end

    def remove(player_id, rate)
      Storage.redis_pool.with {|conn| conn.ZREM('lobby:players', player_id)}
    end

    def players(rate)
      rated = Storage.redis_pool.with {|conn| conn.ZRANGEBYSCORE('lobby:players_rate', '-inf', '+inf', :limit, 0, 50)}
      Reactor.actors(rated.uniq).compact.map{|p| p.lobby_info }
    end

    def generate_ai(level)
      AI_PRESETS.map {|uid, preset| [uid, preset[:name], [preset[:level] + level, 0].max]}
    end

    def invite(sender_uid, opponent_uid)
      if sender_uid == opponent_uid
        TheLogger.error("Player can't invite itself!")
        return
      end

      if frozen?(sender_uid)
        Reactor.actor(sender_uid).send_cancel_invite_to_battle
        return
      end

      freeze!(sender_uid)

      @invites[opponent_uid] ||= []
      @invites[opponent_uid] << {
        sender_uid: sender_uid,
        exp_time: Time.now.to_i + INVITE_LIVE_TIME,
        sent: false,
        token: SecureRandom.hex(5)
      }
    end

    def dispatch!
      @invites = ThreadSafe::Hash.new
      @frozen_players = ThreadSafe::Cache.new

      @thread = Thread.new do
        loop do
          process_invites_queue
          sleep 3
        end
      end
    end

    # private

    def has_invites?(player_uid)
      @invites[player_uid].nil? || @invites[player_uid].empty?
    end

    def frozen?(player_uid)
      @frozen_players[player_uid]
    end

    def freeze!(player_uid)
      @frozen_players[player_uid] = true
    end

    def unfreeze!(player_uid)
      @frozen_players.delete(player_uid)
    end

    def process_invites_queue
      current_time = Time.now.to_i

      @invites.each do |player_id, invitations|

        next if invitations.empty?

        invitation = invitations.first

        token = invitation[:token]
        sender_uid = invitation[:sender_uid]

        if invitation[:exp_time] < current_time
          # invitaion expired
          TheLogger.info("Invitation P:(sender) #{sender_uid}, T:#{token} expired.")
          cancel_invitation(player_id, token)
        elsif invitation[:sent] == false
          # send invitaions
          opponent_info = Reactor.actor(sender_uid).lobby_info
          Reactor.actor(player_id).send_invite_to_battle({
            token: token,
            info: opponent_info
          })
          # mark invitation as sended
          invitation[:sent] = true
          TheLogger.info("Invitation P:(sender) #{sender_uid} sent to P:#{player_id}, T:#{token} sended.")
        end
      end

    end

    def process_invite(player_id, invite_info)
      token, decision = invite_info

      if decision
        invite = @invites[player_id].find{|i| i[:token] == token}
        if invite
          freeze!(player_id)
          # Player accepted battle
          @invites[player_id].each do |invite|
            Reactor.actor(invite[:sender_uid]).send_cancel_invite_to_battle
          end
          @invites[player_id].clear
          puts('create battle')
        end
      else
        cancel_invitation(player_id, token)
      end
    end

    def cancel_invitation(player_id, token)
      @invites[player_id].delete_if do |invite|
        if invite[:token] == token

          sender_uid = invite[:sender_uid]
          TheLogger.info("Invitation canceled P:(sender) #{sender_uid}, T:#{invite[:token]}.")

          unfreeze!(sender_uid)

          [player_id, sender_uid].each{|uid| Reactor.actor(uid).send_cancel_invite_to_battle}
        end

        invite[:token] == token
      end

    end

  end
end
