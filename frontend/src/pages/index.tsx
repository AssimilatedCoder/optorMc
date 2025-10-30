import Head from 'next/head'
import { useState } from 'react'

export default function Home() {
  const [prompt, setPrompt] = useState('')
  const [loading, setLoading] = useState(false)
  const [downloadUrl, setDownloadUrl] = useState<string | null>(null)
  const [error, setError] = useState('')

  const handleGenerate = async () => {
    setLoading(true)
    setError('')
    setDownloadUrl(null)
    try {
      const res = await fetch('http://localhost:5000/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt }),
      })
      if (!res.ok) throw new Error('Generation failed')
      const blob = await res.blob()
      setDownloadUrl(URL.createObjectURL(blob))
    } catch (e) {
      setError('Something went wrong!')
    }
    setLoading(false)
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-100 via-gray-50 to-green-50">
      <Head>
        <title>optorMc.com</title>
      </Head>
      <main className="bg-white/90 rounded-xl shadow-lg p-10 w-full max-w-lg border border-green-200">
        <header className="mb-4 flex flex-col items-center">
          <h1 className="font-extrabold text-3xl tracking-tight text-green-800 mb-1">optorMc</h1>
          <span className="text-green-600 font-medium text-lg">Generate bespoke Minecraft mods & packs locally</span>
        </header>
        <div className="flex flex-col gap-3 mt-6">
          <textarea
            className="resize-none rounded border p-3 border-green-200 focus:ring-2 focus:ring-green-300 text-base outline-none"
            rows={3}
            placeholder="Describe your mod or resource pack..."
            value={prompt}
            onChange={e => setPrompt(e.target.value)}
            disabled={loading}
          />
          <button
            className="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-4 rounded disabled:bg-green-300"
            onClick={handleGenerate}
            disabled={!prompt || loading}
          >
            {loading ? 'Generating...' : 'Generate'}
          </button>
        </div>
        {error && <div className="text-red-600 mt-3 text-sm text-center">{error}</div>}
        {downloadUrl && (
          <div className="mt-6 flex flex-col items-center">
            <a className="bg-cyan-500 hover:bg-cyan-600 text-white py-2 px-6 rounded font-semibold" href={downloadUrl} download="output.zip">Download ZIP</a>
          </div>
        )}
        <div className="mt-8 text-sm text-gray-400 text-center">
          <span>Powered locally by open source AI &mdash; optorMc.com</span>
        </div>
      </main>
    </div>
  )
}
