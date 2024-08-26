import App
import Vapor

var env = try Environment.detect()

try LoggingSystem.bootstrap(from: &env) { level in
    return { label in
        MultiplexLogHandler([
            ConsoleLogger(label: label, console: Terminal(), level: level),
//            ConsoleLogger(label: label, console: RemoteTerminal.default, level: level),
//            FileLogger(label: label, filePath: DirectoryConfiguration.detect().publicDirectory + "logs.txt", level: level)
        ])
    }
}

let app = Application(env)
app.http.server.configuration.hostname = "0.0.0.0"
defer { app.shutdown() }
try configure(app)
try app.run()
