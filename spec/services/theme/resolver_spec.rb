# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Theme::Resolver do
  describe '.css_vars' do
    it 'resolves the arcade / Neon Tokyo / dark default to the prototype values' do
      vars = described_class.css_vars(skin: 'arcade', palette: 0, dark: true)

      expect(vars['--bg0']).to eq('#0a0712')
      expect(vars['--ink']).to eq('#f3ecff')
      expect(vars['--n1']).to eq('#ff2d95')
      expect(vars['--f-display']).to include('Zen Dots')
      expect(vars['--r-md']).to eq('16px')
      expect(vars['--on-accent']).to eq('#0a0712')
    end

    it 'switches colour maps between dark and light' do
      dark  = described_class.css_vars(skin: 'arcade', palette: 0, dark: true)
      light = described_class.css_vars(skin: 'arcade', palette: 0, dark: false)

      expect(dark['--bg0']).not_to eq(light['--bg0'])
      expect(light['--on-accent']).to eq('#ffffff')
    end

    it 'applies per-skin structural tokens (famicom hard edges, zero radius)' do
      vars = described_class.css_vars(skin: 'famicom', palette: 0, dark: true)

      expect(vars['--r-md']).to eq('0px')
      expect(vars['--bd']).to eq('3px')
      expect(vars['--f-display']).to include('Press Start 2P')
    end

    it 'falls back to a defined edge token when the palette omits one' do
      # arcade palettes have no :edge → resolver derives it (#000 in dark)
      expect(described_class.css_vars(skin: 'arcade', palette: 0, dark: true)['--edge']).to eq('#000')
      # kawaii palettes define :edge explicitly
      expect(described_class.css_vars(skin: 'kawaii', palette: 0, dark: true)['--edge']).to eq('#1c0c1e')
    end

    it 'clamps out-of-range palette indices instead of erroring' do
      expect { described_class.css_vars(skin: 'pitch', palette: 99, dark: false) }.not_to raise_error
    end
  end

  describe '.style_string' do
    it 'renders a CSS-declaration string for a <body style> attribute' do
      str = described_class.style_string(skin: 'arcade', palette: 0, dark: true)

      expect(str).to include('--bg0:#0a0712')
      expect(str).to include(';--ink:#f3ecff')
    end
  end
end
