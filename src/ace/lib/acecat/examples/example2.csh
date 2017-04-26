#
xx_examples.e example2 input=ex2 structdef="" recindex="" filter="" <<EOF

EOF
xx_examples.e example2 input=ex2 structdef="example2.h" recindex=N <<EOF
c1 c2
N > 2
EOF
xx_examples.e example2 input=ex2 structdef="example2.h" recindex=X filter="" <<EOF
c1 c2
EOF
xx_examples.e example2 input=ex2 structdef="example2.h" recindex=X filter="" <<EOF
c2 c1
EOF
