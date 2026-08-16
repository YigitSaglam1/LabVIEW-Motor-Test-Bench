<?xml version='1.0' encoding='UTF-8'?>
<Project Type="Project" LVVersion="26008000">
	<Property Name="NI.LV.All.SaveVersion" Type="Str">26.0</Property>
	<Property Name="NI.LV.All.SourceOnly" Type="Bool">true</Property>
	<Item Name="My Computer" Type="My Computer">
		<Property Name="server.app.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="server.control.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="server.tcp.enabled" Type="Bool">false</Property>
		<Property Name="server.tcp.port" Type="Int">0</Property>
		<Property Name="server.tcp.serviceName" Type="Str">My Computer/VI Server</Property>
		<Property Name="server.tcp.serviceName.default" Type="Str">My Computer/VI Server</Property>
		<Property Name="server.vi.callsEnabled" Type="Bool">true</Property>
		<Property Name="server.vi.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="specify.custom.address" Type="Bool">false</Property>
		<Item Name="Acquisition" Type="Folder">
			<Item Name="DAQ_Initialize.vi" Type="VI" URL="../DAQ_Initialize.vi"/>
			<Item Name="DAQ_ReadMeasurements.vi" Type="VI" URL="../DAQ_ReadMeasurements.vi"/>
			<Item Name="DAQ_Shutdown.vi" Type="VI" URL="../DAQ_Shutdown.vi"/>
			<Item Name="SensorScaling.vi" Type="VI" URL="../SensorScaling.vi"/>
		</Item>
		<Item Name="Logging" Type="Folder">
			<Item Name="TDMS_LogMeasurements.vi" Type="VI" URL="../TDMS_LogMeasurements.vi"/>
		</Item>
		<Item Name="Main" Type="Folder">
			<Item Name="MotorTestBench_Main.vi" Type="VI" URL="../MotorTestBench_Main.vi"/>
		</Item>
		<Item Name="Modbus" Type="Folder">
			<Item Name="Modbus_Initialize.vi" Type="VI" URL="../Modbus_Initialize.vi"/>
			<Item Name="Modbus_ReadMeasurements.vi" Type="VI" URL="../Modbus_ReadMeasurements.vi"/>
			<Item Name="Modbus_Shutdown.vi" Type="VI" URL="../Modbus_Shutdown.vi"/>
			<Item Name="Modbus_WriteCommands.vi" Type="VI" URL="../Modbus_WriteCommands.vi"/>
		</Item>
		<Item Name="Safety" Type="Folder">
			<Item Name="EvaluateMotorLimits.vi" Type="VI" URL="../EvaluateMotorLimits.vi"/>
			<Item Name="InjectFaults.vi" Type="VI" URL="../InjectFaults.vi"/>
		</Item>
		<Item Name="Simulation" Type="Folder">
			<Item Name="MotorSimulator.vi" Type="VI" URL="../MotorSimulator.vi"/>
		</Item>
		<Item Name="TypeDefs" Type="Folder">
			<Item Name="FaultInjectionMode.ctl" Type="VI" URL="../FaultInjectionMode.ctl"/>
			<Item Name="MotorMeasurements.ctl" Type="VI" URL="../MotorMeasurements.ctl"/>
		</Item>
		<Item Name="Package Dependencies" Type="IIO Ladder Diagram">
			<Property Name="NI.SortType" Type="Int">0</Property>
		</Item>
		<Item Name="Dependencies" Type="Dependencies"/>
		<Item Name="Build Specifications" Type="Build"/>
	</Item>
</Project>
