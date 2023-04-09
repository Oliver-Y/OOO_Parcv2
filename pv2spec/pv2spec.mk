#=========================================================================
# pv2spec Subpackage
#=========================================================================

pv2spec_deps = \
  vc \
  imuldiv \
  pcache \

pv2spec_srcs = \
  pv2spec-CoreDpath.v \
  pv2spec-CoreDpathRegfile.v \
  pv2spec-CoreDpathAlu.v \
  pv2spec-CoreScoreboard.v \
  pv2spec-CoreReorderBuffer.v \
  pv2spec-CoreCtrl.v \
  pv2spec-Core.v \
  pv2spec-InstMsg.v \

pv2spec_test_srcs = \
  pv2spec-InstMsg.t.v \

pv2spec_prog_srcs = \
  pv2spec-sim.v \
  pv2spec-randdelay-sim.v \

