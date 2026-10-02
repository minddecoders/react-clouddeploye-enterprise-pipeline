import style from './home.module.css'
import branches from './About/Muslim girl animation.jpg'
import account from './About/Margherita Pizza.jpeg'
function Home(){
 const five  = ()=> {
         let x = "Sidra" ;  
         return x;     
 }
  return(
   <>
   
   <div className={style.home}>
    <div className={style.naiveBar}>
      <div  className={style.left} >
          <p>Abstract</p>
          <p>|</p>
          <p>Help Center</p>
      </div>
      <div className={style.right}>
        <button className={style.submit}>Submit a request</button>
        <button className={style.sign}>Sign in</button>
      </div>
 </div>

      <div className={style.big} style={{backgroundImage:`url(${account})`}} >
        <div className={style.title}>
        <h1>How can we help? {five()}</h1>
        </div>
        <div className={style.search}>
         <input type="text" placeholder="Search " />
        </div>
      </div>


      <div className={style.mainContent}>

        <div  className={style.box}>
         <img src={branches} alt="" />        
       <div className={style.headingParagraph}>
        <h1>Branches</h1>
        <p>Abstract Branches lets you manages,version, and document your designs in one place. </p>
        <a href=''>Learn More  ➡</a>
       </div>
       </div>

          <div  className={style.box}>
         <img src={branches} alt="" />        
       <div className={style.headingParagraph}>
        <h1>Branches</h1>
        <p>Abstract Branches lets you manages,version, and document your designs in one place. </p>
        <a href=''>Learn More  ➡</a>
       </div>
       </div>

          <div  className={style.box}>
         <img src={branches} alt="" />        
       <div className={style.headingParagraph}>
        <h1>Branches</h1>
        <p>Abstract Branches lets you manages,version, and document your designs in one place. </p>
        <a href=''>Learn More  ➡</a>
       </div>
       </div>

          <div  className={style.box}>
         <img src={account} alt="" />        
       <div className={style.headingParagraph}>
        <h1>Branches</h1>
        <p>Abstract Branches lets you manages,version, and document your designs in one place. </p>
        <a href=''>Learn More  ➡</a>
       </div>
       </div>

          <div  className={style.box}>
         <img src={branches} alt="" />        
       <div className={style.headingParagraph}>
        <h1>Branches</h1>
        <p>Abstract Branches lets you manages,version, and document your designs in one place. </p>
        <a href=''>Learn More  ➡</a>
       </div>
       </div>

          <div  className={style.box}>
         <img src={account} alt="" />        
       <div className={style.headingParagraph}>
        <h1>Branches</h1>
        <p>Abstract Branches lets you manages,version, and document your designs in one place. </p>
        <a href=''>Learn More  ➡</a>
       </div>
       </div>

         
 
      </div>

       <div className={style.footer}>
      <div >
        <ul><h4>Abstract</h4>
          <li>Branches</li>
        </ul>
      </div>

      <div >
        <ul><h4>Resources</h4>
          <li>Blog </li>
          <li>Help Center</li>
          <li>Realease Notes</li>
          <li>Status</li>
        </ul>
      </div>

      <div>
        <ul><h4>Community</h4>
          <li>Twitter</li>
          <li>Linkedin</li>
          <li>Facebook</li>
          <li>Dribbble</li>
          <li>Podcast</li>
        </ul>
      </div>

      <div >
        <div>
        <ul><h4>Company</h4>
          <li>About Us </li>
          <li>Careers</li>
          <li>Legal</li>
        </ul>
        <ul>
          <h4>Contact Us</h4>
          <li>info@abstract.com</li>
        </ul>
        </div>
      </div>

      <div className={style.coyright}>
        <ul>
        <li>Copyright 2022</li>
        <li>Abstract Studio Design .Inc.</li>
        <li>All rights reserved</li>
        </ul>
      </div>

      </div>
        
   </div>
   
</>
  );
}
export default Home;