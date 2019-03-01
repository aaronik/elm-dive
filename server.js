const path       = require('path')
const express    = require('express')
const spawn      = require('child_process').spawnSync
const bodyParser = require('body-parser')

const app = express()

app.use(bodyParser.json())

// Serve all the static files
app.use(express.static(path.resolve(__dirname, './dist')))

// Serve the html
app.get('/', (req, res) => {
  res.sendFile(path.resolve(__dirname, './index.html'))
})

// Return list of networks from nmcli
app.get('/networks', (req, res) => {
  const cliBuf = spawn('nmcli', ['-f', 'in-use,ssid,security,bssid,chan,rate,signal,bars,device', 'dev', 'wifi', 'list'])
  const cliStdOut = cliBuf.stdout.toString()
  const cliStdErr = cliBuf.stderr.toString()

  if (cliStdErr) return res.status(503).send(cliStdErr)
  else           return res.send(cliStdOut)
})

// Join a network
app.post('/join', (req, res) => {
  const { ssid, password } = req.body

  const cliBuf = spawn('nmcli', ['dev', 'wifi', 'connect', ssid, 'password', password, 'ifname', 'wlp59s0'])
  const cliStdOut = cliBuf.stdout.toString()
  const cliStdErr = cliBuf.stderr.toString()

  if (cliStdErr) return res.status(503).send(cliStdErr)
  else           return res.status(201).send(cliStdOut)
})

// Fire up the serving!
app.listen(4444, console.log.bind(console, 'App listening on port 4444!'))
