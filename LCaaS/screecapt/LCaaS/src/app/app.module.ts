import { CommonModule } from '@angular/common';
import { HttpClient, HttpClientModule } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { TranslateLoader, TranslateModule } from '@ngx-translate/core';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';
import { DataTablesModule } from 'angular-datatables';
import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { AuthGuard } from './shared';
import { NgxGraphModule } from '@swimlane/ngx-graph';
import { NgxChartsModule } from '@swimlane/ngx-charts';
import { AngularDraggableModule } from 'angular2-draggable';
import { FormsModule } from '@angular/forms';

// import { APP_BASE_HREF } from '@angular/common'; 
// import { Inject } from '@angular/core';

// AoT requires an exported function for factories
export const createTranslateLoader = (http: HttpClient) => {
    /* for development
    return new TranslateHttpLoader(
        http,
        '/start-angular/SB-Admin-BS4-Angular-6/master/dist/assets/i18n/',
        '.json'
    ); */
    return new TranslateHttpLoader(http, './assets/i18n/', '.json');
};

@NgModule({
    imports: [
        CommonModule,
        BrowserModule,
        BrowserAnimationsModule,
        HttpClientModule,
        NgxGraphModule,
        NgxChartsModule,
        AngularDraggableModule,
        TranslateModule.forRoot({
            loader: {
                provide: TranslateLoader,
                useFactory: createTranslateLoader,
                deps: [HttpClient]
            }
        }),
        AppRoutingModule,
        DataTablesModule
    ],
    declarations: [AppComponent],
     providers: [AuthGuard],
    // providers: [
    //     {
    //     provide: APP_BASE_HREF,
    //     useValue: window['base-href']
    //   },
    //   AuthGuard],
    bootstrap: [AppComponent]
})
export class AppModule {
    //  constructor(@Inject(APP_BASE_HREF) private baseHref:string){}
}
