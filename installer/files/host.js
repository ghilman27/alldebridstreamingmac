/* globals global, require, process, Buffer */
'use strict';



function lazyRequire(lib, name) {
  if (!name) {
    name = lib;
  }
  global.__defineGetter__(name, function() {
    return require(lib);
  });
  return global[name];
}

var spawn = require('child_process').spawn;
var fs = require('fs');
var net = lazyRequire('net');
var os = lazyRequire('os');
var path = lazyRequire('path');

var server;
var files = [];
var sprocess = [];

var config = {
  version: '0.2',
  nodeVersion: process.version
};
// closing node when parent process is killed
process.stdin.resume();
process.stdin.on('end', () => {
  files.forEach(file => {
    try {
      fs.unlink(file);
    }
    catch (e) {}
  });
  sprocess.forEach(ps => ps.kill());
  try {
    server.close();
    server.unref();
  }
  catch (e) {}
  process.exit();
});

/////////////////process.on('uncaughtException', e => console.error(e));

function observe(msg, push, done) {

  if (msg.cmd === 'version') {
    push({
      version: config.version,
      nodeVersion: config.nodeVersion,
    });
    done();
    process.exit()
  } else if (msg.cmd === 'spec') {
    push({
      version: config.version,
      nodeVersion: config.nodeVersion,
      env: process.env,
      separator: path.sep,
      tmpdir: os.tmpdir()
    });
    done();
    process.exit()
  }
  else if (msg.cmd === 'echo') {
    push(msg)
    done()
    process.exit()
  }
  else if (msg.cmd === 'spawn') {
    if (msg.env) {
      msg.env.forEach(n => process.env.PATH += path.delimiter + n);
    }
    const p = Array.isArray(msg.command) ? path.join(...msg.command) : msg.command;
    const sp = spawn(p, msg.arguments || [], Object.assign({env: process.env}, msg.properties));

    if (msg.kill) {
      sprocess.push(sp);
    }

    sp.stdout.on('data', stdout => push({stdout}));
    sp.stderr.on('data', stderr => push({stderr}));
    sp.on('close', code => {
      push({
        cmd: msg.cmd,
        code
      });
      done();
      process.exit()
    });
    sp.on('error', e => {
      push({
        code: 1007,
        error: e.message
      });
      done();
      process.exit()
    });
  }
  else if (msg.cmd === 'exec') {
    if (msg.env) {
      msg.env.forEach(n => process.env.PATH += path.delimiter + n);
    }
    const p = Array.isArray(msg.command) ? path.join(...msg.command) : msg.command;
    const sp = spawn(p, msg.arguments || [], Object.assign({
      env: process.env,
      detached: true
    }, msg.properties));
    if (msg.kill) {
      sprocess.push(sp);
    }
    let stderr = '';
    let stdout = '';
    sp.stdout.on('data', data => stdout += data);
    sp.stderr.on('data', data => stderr += data);
    sp.on('close', code => {
      push({
        close: true,
        code: code,
        stderr,
        stdout,
      });
      done()
      process.exit()
    });
    sp.on('error', code => {
      if(code.code = "ENOENT") {
        push({
          error: 'wrongPath',
          path: code.path,
          url: msg.arguments[0],
          stderr,
          stdout,
        });
        done();
      } else {
        push({
          error: 'unknownError',
          fullError: code,
          stderr,
          stdout,
        });
      }
      done()
      process.exit()
    });
  }
  else if (msg.cmd === 'env') {
    push({
      env: process.env
    });
    done()
    process.exit()
  }
  else if (msg.cmd === 'checkPath') {
    if (fs.existsSync(msg.path)) {
      push({
        exists: true,
        path: msg.path
      });
    } else {
      push({
        exists: false,
        path: msg.path
      });
    }
    
    done()
    process.exit()
  }
  else {
    push({
      error: 'cmd is unknown !!' + msg.cmd,
      cmd: msg.cmd,
      code: 1000,
      fullCmd: cmd
    });
    done()
    process.exit()
  }
}
/* message passing */
var nativeMessage = require('./messaging');

var input = new nativeMessage.Input();
var transform = new nativeMessage.Transform(observe);
var output = new nativeMessage.Output();

process.stdin
    .pipe(input)
    .pipe(transform)
    .pipe(output)
    .pipe(process.stdout);
