getInfo = (robot, messages, callback) ->
  data = JSON.stringify({
    model: "gpt-3.5-turbo",
    messages: messages
  })
  options =
    # don't verify server certificate against a CA, SCARY!
    rejectUnauthorized: false
  robot.http("https://api.openai.com/v1/chat/completions",options)
    .header('Accept', 'application/json')
    .header('Content-type', 'application/json')
    .header('Authorization','Bearer YOUR_OPENAI_KEY')
    .post(data) (err, res, body) ->
        callback(err, res, body)

module.exports = (robot) ->
  prompt = []
  record = ""
  del_tag = false
  total_tokens = 0
  max_tokens = 2800
  top_tokens = 4000

  robot.respond /(.*)/i, (msg)  ->
    tmp_prompt = prompt
    mes = msg.match[1]
    # msg.send "#{mes.length}"
    
    switch mes
      when '帮助', 'help'
        msg.send "聊天机器人使用介绍："
        msg.send "本机器人基于OpenAI最新发布的ChatGPT3.5版本的turbo接口实现"
        msg.send "直接发送文字即可开启聊天"
        msg.send "请注意：由于系统限制，暂时不支持上下文语境"
      else
      
        tmp = {
          role: "user",
          content: "#{mes}"
        }
        prompt = []
        prompt = prompt.concat tmp
       
        mess = prompt
        getInfo robot, mess, (err, res, body) ->
          # msg.send "#{err}"
          if res.statusCode isnt 200
            data = JSON.parse body
            # data = body

            msg.send "#{data.error.message}"
            if data.error.message.includes "This model's maximum context length is"
              msg.send "很抱歉，您发送的消息过长，请重新发送"
          else
            # msg.send "Got back #{body}"
            data = JSON.parse body
            respond = ""
            if data.choices[0].message.content.startsWith '\n'
              r = data.choices[0].message.content.split '\n'
              
              i = 0
              for item in r
                if i >= 2
                    respond = respond + item
                    if (i+1) != r.length
                        respond = respond + "\n"
                i = i + 1
            else
              respond = data.choices[0].message.content
            try
              respond = respond.replace /\$\$(.*?)\$\$/g, '\\[$1\\]'
            catch Error
              e = Error
            try
              respond = respond.replace /\$(.*?)\$/g,'\n\n\\[$1\\]'
            catch Error
              e = Error
            total_tokens = data.usage.total_tokens
            msg.send "#{respond}"
                