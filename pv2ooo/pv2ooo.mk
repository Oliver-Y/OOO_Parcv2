#=========================================================================
# pv2ooo Subpackage
#=========================================================================

pv2ooo_deps = \
  vc \
  imuldiv \
  pcache \

pv2ooo_srcs = \
  pv2ooo-CoreDpath.v \
  pv2ooo-CoreDpathRegfile.v \
  pv2ooo-CoreDpathAlu.v \
  pv2ooo-CoreScoreboard.v \
  pv2ooo-CoreReorderBuffer.v \
  pv2ooo-CoreCtrl.v \
  pv2ooo-Core.v \
  pv2ooo-InstMsg.v \

pv2ooo_test_srcs = \
  pv2ooo-InstMsg.t.v \

pv2ooo_prog_srcs = \
  pv2ooo-sim.v \
  pv2ooo-randdelay-sim.v \

