module DocumentQueuesHelper
  def priority_color(priority)
    case priority.to_s
    when 'critical'
      'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200'
    when 'urgent'
      'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200'
    when 'high'
      'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200'
    when 'normal'
      'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
    when 'low'
      'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200'
    else
      'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200'
    end
  end
end