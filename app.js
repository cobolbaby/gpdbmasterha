const http = require('http');

http.createServer(function (request, response) {

    let data = {"code": 0, "message": "success"};

    // 发送 HTTP 头部 
    // HTTP 状态值: 200 : OK
    // 内容类型: text/plain
    response.writeHead(200, {'Content-Type': 'application/json'});
    response.end(JSON.stringify(data));

}).listen(9000);