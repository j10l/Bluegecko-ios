//
//  RSSIGraphViewLineChartView.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 21/04/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import Charts

class RSSIGraphLineChartView: LineChartView {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupChart()
    }
    
    deinit {
        debugPrint("RSSIGraphLineChartView deinit")
    }
    
    private func setupChart() {
        disableLegend()
        setupOffsets()
        setupScaling()
        setupYAxis()
        setupXAxis()
        setupLabels()
        
        addYAxisLines(withColor: RSSIConstants.axisRed)
        addXAxisLines(withColor: RSSIConstants.axisRed)
        
        resetChart()
    }
    
    private func setupScaling() {
        scaleXEnabled = true
        scaleYEnabled = true
        doubleTapToZoomEnabled = false
        highlightPerTapEnabled = false
        highlightPerDragEnabled = true
    }
    
    private func disableLegend() {
        chartDescription?.enabled = false
        legend.enabled = false
        rightAxis.enabled = false
    }
    
    private func setupOffsets() {
        minOffset = 0
        extraTopOffset = 30
        extraLeftOffset = 0
        extraBottomOffset = 30
        extraRightOffset = 15
    }
    
    private func setupYAxis() {
        leftAxis.valueFormatter = RSSIGraphYAxisValueFormatter()
        leftAxis.axisMinimum = RSSIConstants.startYAxisMinimum
        leftAxis.axisMaximum = RSSIConstants.startYAxisMaximum
        leftAxis.granularity = RSSIConstants.yAxisGranularity
        leftAxis.drawGridLinesEnabled = false
        leftAxis.drawAxisLineEnabled = false
        leftYAxisRenderer = RSSIGraphYAxisRenderer(viewPortHandler: leftYAxisRenderer.viewPortHandler,
                                                             yAxis: leftAxis,
                                                             transformer: leftYAxisRenderer.transformer)
    }
    
    private func setupXAxis() {
        xAxis.valueFormatter = RSSIGraphXAxisValueFormatter()
        xAxis.axisMinimum = RSSIConstants.startXAxisMinimum
        xAxis.axisMaximum = RSSIConstants.startXAxisMaximum
        xAxis.granularity = RSSIConstants.xAxisGranularity
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxisRenderer = RSSIGraphXAxisRenderer(viewPortHandler: xAxisRenderer.viewPortHandler,
                                                         xAxis: xAxis,
                                                         transformer: xAxisRenderer.transformer)
    }
    
    private func setupLabels() {
        xAxis.labelPosition = .bottom
        xAxis.setLabelCount((RSSIConstants.maxNumberOfVisibleXValuesInt / 5) + 1, force: false)
    }
    
    private func addYAxisLines(withColor color: UIColor) {
        let axisLine = createAxisLine(withColor: color)
        
        leftAxis.addLimitLine(axisLine)
        
        for i in stride(from: leftAxis.axisMinimum, through: leftAxis.axisMaximum, by: leftAxis.granularity) {
            guard i != 0 else { continue }
            
            let gridLine = createGridLine(withColor: color, andPosition: i)
            
            leftAxis.addLimitLine(gridLine)
        }
    }
    
    private func addXAxisLines(withColor color: UIColor) {
        xAxis.removeAllLimitLines()
        for i in stride(from: xAxis.axisMinimum, through: xAxis.axisMaximum, by: xAxis.granularity) {
            let gridLine = createGridLine(withColor: color, andPosition: i)
            
            xAxis.addLimitLine(gridLine)
        }
    }
    
    private func createAxisLine(withColor color: UIColor) -> ChartLimitLine {
        let axisLine = ChartLimitLine(limit: 0, label: "")
        
        axisLine.lineColor = color
        axisLine.lineWidth = 1
        
        return axisLine
    }
    
    private func createGridLine(withColor color: UIColor, andPosition position: Double) -> ChartLimitLine {
        let gridLine = ChartLimitLine(limit: position, label: "")
        
        gridLine.lineColor = color
        gridLine.lineWidth = 1
        gridLine.lineDashPhase = 5
        gridLine.lineDashLengths = [3]
        
        return gridLine
    }
    
    // MARK: Public methods
    
    func resetChart() {
        leftAxis.axisMinimum = RSSIConstants.startYAxisMinimum
        leftAxis.axisMaximum = RSSIConstants.startYAxisMaximum
        xAxis.axisMinimum = RSSIConstants.startXAxisMinimum
        xAxis.axisMaximum = RSSIConstants.startXAxisMaximum

        lineData?.clearValues()
        data = LineChartData()
        setVisibleXRangeMinimum(RSSIConstants.maxNumberOfVisibleXValues)
        setVisibleXRangeMaximum(RSSIConstants.maxNumberOfVisibleXValues)
        setVisibleYRangeMinimum(RSSIConstants.maxNumberOfVisibleYValues, axis: .left)
        setVisibleYRangeMaximum(RSSIConstants.maxNumberOfVisibleYValues, axis: .left)
    }
    
    func updateViewPosition() {
        var xLeft: Double
        
        let axisMaximum = xAxis.axisMaximum
        if !(highestVisibleX + RSSIConstants.approximationError  < axisMaximum) {
            xLeft = axisMaximum - visibleXRange
        } else {
            xLeft = highestVisibleX - visibleXRange
        }
        
        let top = valueForTouchPoint(point: CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentTop),
                                               axis: .left).y
        
        let bottom = valueForTouchPoint(point: CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentBottom),
                                                  axis: .left).y
        
        let yCenter = (top + bottom) / 2.0
        moveViewTo(xValue: xLeft, yValue: yCenter, axis: .left)
    }
    
    func updateXAxisGridLines() {
        for i in stride(from: xAxis.axisMinimum, through: xAxis.axisMaximum, by: xAxis.granularity) {
            if let _ = xAxis.limitLines.first(where: { Int($0.limit) == Int(i) }) {
                continue
            }
            let gridLine = createGridLine(withColor: RSSIConstants.axisRed, andPosition: i)
            
            xAxis.addLimitLine(gridLine)
        }
    }
    
    func checkIfDataSetExist(withLabel label: String) -> Bool {
        guard let data = self.data else { return false }
        return !data.dataSets.contains(where: { $0.label == label })
    }
    
    func addDataSetFor(_ entries: [ChartDataEntry], identifier: String, color: UIColor) {
        let dataSet = LineChartDataSet(entries: entries, label: identifier)
        cofigureDataSet(dataSet: dataSet)
        dataSet.colors = [color]
        
        lineData?.addDataSet(dataSet)
    }

    private func cofigureDataSet(dataSet: LineChartDataSet) {
        dataSet.mode = .linear
        dataSet.drawCirclesEnabled = false
        dataSet.lineWidth = RSSIConstants.unselectedLineWidth
        dataSet.drawFilledEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.fillAlpha = 3
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.drawVerticalHighlightIndicatorEnabled = false
    }
}
