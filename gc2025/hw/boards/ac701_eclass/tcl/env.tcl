# E-class AC701 build: own project dirs so the C-class fpga_project is never touched.
global home_dir fpga_dir ip_project_dir core_project_dir ip_project core_project board_dir
set board_dir [ file dirname [ file dirname [ file normalize [ info script ] ] ] ]
set home_dir .
set fpga_dir $home_dir/fpga_project_eclass
set ip_project_dir $fpga_dir/manage_ip
set core_project_dir $fpga_dir/e-class
set ip_project manage_ip
set core_project e-class
