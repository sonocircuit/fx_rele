FxRele : FxBase {
	
	*new { 
		var ret = super.newCopyArgs(nil, \none, (
			amp: 1,
			timeL: 0.5,
			timeR: 0.52,
			mode: 0,
			fb: 0.64,
			hzLpf: 8000,
			hzHpf: 120,
			mod: 0.08
		), nil, 0.5);
		^ret;
	}
	
	*initClass {
		FxSetup.register(this.new);
	}
	
	subPath {
		^"/fx_rele";
	}  
	
	symbol {
		^\fxRele;
	}
	
	addSynthdefs {
		SynthDef.new(\fxRele, { |inBus, outBus|	
			var modHz = 12, tMax = 2, modF = 0.008;
			
			var modT = modF * \mod.kr(0);
			var modOsc = LFNoise2.ar(modHz);
			var tL = modOsc.range(\timeL.kr(0.4), \timeL.kr(0.4) + modT).lag(0.24);
			var tR = Select.ar(\mode.kr(0) < 1,[modOsc.range(\timeR.kr(0.8) + modT, \timeR.kr(0.8)), tL]).lag(0.24);
			
			var rtn = LocalIn.ar(2);
			var rtnL = Select.ar(\mode.kr(0) < 2, [rtn[1], rtn[0]]);
			var rtnR = Select.ar(\mode.kr(0) < 2, [rtn[0], rtn[1]]);
			
			var dry = In.ar(inBus, 2);
			var dlyL = DelayC.ar(dry[0] + (rtnL * \fb.kr(0.6)), tMax, tL);
			var dlyR = DelayC.ar(dry[1] + (rtnR * \fb.kr(0.6)), tMax, tR);
			
			var dly = LeakDC.ar([dlyL, dlyR]);
			dly = HPF.ar(LPF.ar(dly, \hzLpf.kr(1600)), \hzHpf.kr(80));
			LocalOut.ar(dly.tanh);
			Out.ar(outBus, dly * \amp.kr(1));
		}).add;
	}
	
}
