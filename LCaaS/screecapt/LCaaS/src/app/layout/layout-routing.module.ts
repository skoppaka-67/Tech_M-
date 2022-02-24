import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { LayoutComponent } from './layout.component';

const routes: Routes = [
    {
        path: '',
        component: LayoutComponent,
        children: [
            { path: '', redirectTo: 'dashboard', pathMatch: 'prefix' },
            { path: 'dashboard', loadChildren: './dashboard/dashboard.module#DashboardModule' },
            { path: 'charts', loadChildren: './charts/charts.module#ChartsModule' },
            { path: 'masterinv', loadChildren: './masterinv/masterinv.module#MasterinvModule' },
            { path: 'masterinvApplication', loadChildren: './masterinv-application/masterinv-application.module#MasterinvAppModule' },
            { path: 'forms', loadChildren: './form/form.module#FormModule' },
            { path: 'formsApplication', loadChildren: './form-application/form-application.module#FormAppModule' },
            { path: 'missingcomp', loadChildren: './missingcomp/missingcomp.module#MissingcompModule' },
            { path: 'missingcompApplication', loadChildren: './missingcomp-application/missingcomp-application.module#MissingcompAppModule' },
            { path: 'orphan', loadChildren: './orphan/orphan.module#OrphanModule' },
            { path: 'orphanApplication', loadChildren: './orphan-application/orphan-application.module#OrphanAppModule' },
            { path: 'components', loadChildren: './bs-component/bs-component.module#BsComponentModule' },
            { path: 'xrefReport', loadChildren: './x-ref/x-ref.module#XrefModule' },
            { path: 'xrefApplicationReport', loadChildren: './x-ref-application/x-ref-application.module#XrefApplicationModule' },
            { path: 'progress', loadChildren: './progress/progress.module#ProgressModule' },
            { path: 'deadpara', loadChildren: './deadpara/deadpara.module#DeadparaModule' },
            { path: 'deadparaReport', loadChildren: './deadpara-application/deadpara-application.module#DeadparaAppModule' },
            { path: 'spider', loadChildren: './spider/spider.module#SpiderModule' },
            { path: 'upload', loadChildren: './upload/upload.module#UploadModule' },
            { path: 'bre', loadChildren: './bre/bre.module#BreModule' },
            { path: 'bre-x-ref', loadChildren: './bre-x-ref/bre-x-ref.module#BreXRefModule' },
            { path: 'forwardengineering', loadChildren: './datamodel/datamodel.module#DatamodelModule' },
            { path: 'register', loadChildren: './register/register.module#RegisterModule' },
            { path: 'batchflow', loadChildren: './batchflow/batchflow.module#BatchFlowModule' },
            { path: 'brereport', loadChildren: './brereport/brereport.module#BreReportModule' },
            { path: 'brereport-x-ref', loadChildren: './brereport-x-ref/brereport-x-ref.module#BreReportXRefModule' },
            { path: 'glossary', loadChildren: './glossary/glossary.module#GlossaryModule' },
            { path: 'glossary-application', loadChildren: './glossary-application/glossary-application.module#GlossaryAppModule' },
            { path: 'programprocessflow', loadChildren: './programprocessflow/programprocessflow.module#BsComponentModule' },
            { path: 'programprocessflowExt', loadChildren: './programprocessflow-external/programprocessflow-external.module#BsComponentExtModule' },
            { path: 'programprocessflowEvent', loadChildren: './programprocessflow-eventlist/programprocessflow-eventlist.module#BsComponentEventModule' },
            { path: 'impactReport', loadChildren: './impact/impact.module#ImpactModule' },
            { path: 'callChain', loadChildren: './callchain/callchain.module#CallChainModule' },
            { path: 'callChainApp', loadChildren: './callchain-application/callchain-application.module#CallChainAppModule' },
            { path: 'dropimpact', loadChildren: './dropimpact/dropimpact.module#DropImpactModule' },
            { path: 'dropimpactApp', loadChildren: './dropimpact-application/dropimpact-application.module#DropImpactAppModule' },
            { path: 'controlFlow', loadChildren: './controlflow/controlflow.module#ControlFlowModule' },
            { path: 'controlFlowApp', loadChildren: './controlflow-application/controlflow-application.module#ControlFlowAppModule' },
            { path: 'userguide', loadChildren: './userguide/userguide.module#UserGuideModule' },
            { path: 'commentedlines', loadChildren: './commentedlines/commentedlines.module#CommentedLinesModule' },
            { path: 'commentedlinesApp', loadChildren: './commentedlines-application/commentedlines-application.module#CommentedLinesAppModule' },
            { path: 'cicsscreen', loadChildren: './cicsscreenreport/cicsscreen.module#CicsScreenModule' },
            { path: 'cicsscreenApp', loadChildren: './cicsscreenreport-application/cicsscreenreport-application.module#CicsScreenAppModule' },
            { path: 'naturalMapScreen', loadChildren: './cicsscreen/cicsscreen.module#CicsScreenNatModule' },
            { path: 'cicsrules', loadChildren: './cicsrules/cicsrules.module#CicsRulesModule' },
            { path: 'cicsrulesApp', loadChildren: './cicsrules-application/cicsrules-application.module#CicsRulesAppModule' },
            { path: 'cicsxref', loadChildren: './cicsxref/cics-x-ref.module#CICSXrefModule' },
            { path: 'cicsxrefApp', loadChildren: './cicsxref-application/cicsxref-application.module#CICSXrefAppModule' },
            { path: 'glossaryXref', loadChildren: './glossarynissan/glossary-x-ref.module#GlosssaryXrefModule' },
            { path: 'glossaryXrefTW', loadChildren: './glossarytw/glossarytw-x-ref.module#GlosssaryTWXrefModule' },
            { path: 'spiderchart', loadChildren: './spiderfilter/spiderfilter.module#SpiderFilterModule' },
            { path: 'spiderchartApp', loadChildren: './spiderfilter-application/spiderfilter-application.module#SpiderFilterAppModule' },
            { path: 'brerule', loadChildren: './bre3/bre3.module#Bre3Module' },
            { path: 'bredetailedreport', loadChildren: './breplsql/breplsql.module#BrePlSqlModule'},
            { path: 'bredetailedreportApp', loadChildren: './breplsql-app/breplsql-app.module#BrePlSqlAppModule'},
            { path: 'brereportplsql', loadChildren: './brereportplsql/brereportplsql.module#BreReportPlSqlModule'},
            { path: 'brereportplsqlApp', loadChildren: './brereportplsql-app/brereportplsql-app.module#BreReportPlSqlAppModule'},
            { path: 'callChainplsql', loadChildren: './callchainplsql/callchainplsql.module#CallChainPLSQLModule'},
            { path: 'callChainplsqlApp', loadChildren: './callchainplsql-application/callchainplsql-application.module#CallChainPLSQLAppModule'},
            { path: 'sankey', loadChildren: './sankey/sankey.module#SankeyModule'},
            { path: 'msglog', loadChildren: './msglog/msglog.module#MsgLogModule'},
            { path: 'callChainFilter', loadChildren: './callchainfilter/callchainfilter.module#CallChainFilterModule' },
            { path: 'techspec', loadChildren: './techspec/techspec.module#TechSpecModule' },
        ]
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class LayoutRoutingModule {}
