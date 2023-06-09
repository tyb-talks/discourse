# frozen_string_literal: true

class RandomTopicSelector
  BACKFILL_SIZE = 3000
  BACKFILL_LOW_WATER_MARK = 500

  def self.backfill(category = nil)
    exclude = category&.topic_id

    options = {
      per_page: category ? category.num_featured_topics : 3,
      visible: true,
      no_definitions: true,
    }

    options[:except_topic_ids] = [category.topic_id] if exclude

    if category
      options[:category] = category.id
      # NOTE: at the moment this site setting scopes tightly to a category (excluding subcats)
      # this is done so we don't populate a junk cache
      options[:no_subcategories] = true if SiteSetting.limit_suggested_to_category

      # don't leak private categories into the "everything" group
      options[:guardian] = Guardian.new(Discourse.system_user)
    end

    query = TopicQuery.new(nil, options)

    results =
      query
        .latest_results
        .order("RANDOM()")
        .where(closed: false, archived: false)
        .where("topics.created_at > ?", SiteSetting.suggested_topics_max_days_old.days.ago)
        .limit(BACKFILL_SIZE)
        .reorder("RANDOM()")
        .pluck(:id)

    key = cache_key(category)

    if results.present?
      Discourse.redis.multi do |transaction|
        transaction.rpush(key, results)
        transaction.expire(key, 2.days)
      end
    end

    results
  end

  def self.next(count, category = nil)
    key = cache_key(category)

    results = []

    return results if count < 1

    results =
      Discourse.redis.multi do |transaction|
        transaction.lrange(key, 0, count - 1)
        transaction.ltrim(key, count, -1)
      end

    if !results.is_a?(Array) # Redis is in readonly mode
      results = Discourse.redis.lrange(key, 0, count - 1)
    else
      results = results[0]
    end

    results.map!(&:to_i)

    left = count - results.length

    backfilled = false
    if left > 0
      ids = backfill(category)
      backfilled = true
      results += ids[0...count]
      results.uniq!
      results = results[0...count]
    end

    if !backfilled && Discourse.redis.llen(key) < BACKFILL_LOW_WATER_MARK
      Scheduler::Defer.later("backfill") { backfill(category) }
    end

    results
  end

  def self.cache_key(category = nil)
    "random_topic_cache_#{category&.id}"
  end
end
